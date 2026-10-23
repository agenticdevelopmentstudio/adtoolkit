import type { MessagePort } from 'node:worker_threads';
import type { Storage } from './ports';

// The `Storage` port carried over a MessagePort, so the thread that OWNS the database
// can be a different thread from the ones that use it.
//
// Why: an embedded `file:` libSQL connection runs every statement synchronously on the
// calling thread, and a lock wait spins there for up to busy_timeout (5s). When the API
// thread held its own connection, any read that met the monitor worker's write or WAL
// checkpoint froze the API event loop. /health then timed out, and the supervisor restarted
// the container: the 2026-10-22 outage. Behind this transport, the API thread only ever
// awaits a reply, and the database thread is the only one that blocks.
//
// The server runs calls ONE AT A TIME, FIFO across every connected port: one connection,
// one queue. That leaves nothing to contend for a lock, and it means an async store
// method's statements can never interleave with another call's on the shared connection.
//
// Driver-agnostic: this file serves whatever `Storage` it is handed and never names libSQL.

/** The method tree of a `Storage`: `true` marks a callable, an object a nested store
 *  (e.g. `telemetry.errors`). Sent once by the server so the client can build plain
 *  stub functions instead of a catch-all Proxy, which an `await` would mistake for a
 *  thenable. */
type Shape = { [key: string]: true | Shape };

type Call = { id: number; path: string[]; args: unknown[] };
type Reply = { id: number; ok: true; value: unknown } | { id: number; ok: false; error: WireError };
type Hello = { shape: Shape };

/** An Error flattened for the wire: callers match on `message`, `code` and the `cause`
 *  chain (isUniqueViolation, isDuplicatePeerError), so all three must survive. */
interface WireError {
  name: string;
  message: string;
  stack?: string;
  code?: unknown;
  cause?: WireError;
}

/** A single call slower than this is logged by the server; it holds up the whole queue. */
const SLOW_CALL_MS = 2_000;

function methodsOf(obj: object): string[] {
  const keys = new Set(Object.keys(obj));
  const proto = Object.getPrototypeOf(obj) as object | null;
  if (proto && proto !== Object.prototype) {
    for (const key of Object.getOwnPropertyNames(proto)) if (key !== 'constructor') keys.add(key);
  }
  return [...keys];
}

function shapeOf(obj: object): Shape {
  const shape: Shape = {};
  for (const key of methodsOf(obj)) {
    const value = (obj as Record<string, unknown>)[key];
    if (typeof value === 'function') shape[key] = true;
    else if (value && typeof value === 'object') shape[key] = shapeOf(value);
  }
  return shape;
}

function toWire(err: unknown, depth = 0): WireError {
  if (!(err instanceof Error)) return { name: 'Error', message: String(err) };
  const wire: WireError = { name: err.name, message: err.message, stack: err.stack };
  const code = (err as { code?: unknown }).code;
  if (code !== undefined) wire.code = String(code);
  if (err.cause !== undefined && depth < 4) wire.cause = toWire(err.cause, depth + 1);
  return wire;
}

function fromWire(wire: WireError): Error {
  const err = new Error(wire.message, wire.cause ? { cause: fromWire(wire.cause) } : undefined);
  err.name = wire.name;
  if (wire.stack) err.stack = wire.stack;
  if (wire.code !== undefined) (err as Error & { code?: unknown }).code = wire.code;
  return err;
}

export interface StorageServer {
  /** Start answering calls arriving on `port`. A closed port (its thread exited) just
   *  stops sending; replies to it are dropped. */
  serve(port: MessagePort): void;
}

/** Serve `storage` to any number of ports through ONE FIFO queue. */
export function createStorageServer(storage: Storage): StorageServer {
  const shape = shapeOf(storage);
  let tail: Promise<void> = Promise.resolve();

  async function run(port: MessagePort, { id, path, args }: Call): Promise<void> {
    const started = Date.now();
    let reply: Reply;
    try {
      let target: unknown = storage;
      for (const key of path.slice(0, -1)) target = (target as Record<string, unknown>)[key];
      const method = (target as Record<string, (...a: unknown[]) => unknown>)[path[path.length - 1]];
      reply = { id, ok: true, value: await method.apply(target, args) };
    } catch (err) {
      reply = { id, ok: false, error: toWire(err) };
    }
    const took = Date.now() - started;
    if (took >= SLOW_CALL_MS) console.warn(`[storage] slow call ${path.join('.')} ${took}ms`);
    try {
      port.postMessage(reply);
    } catch (err) {
      // A result the structured clone can't carry: report it rather than leave the caller hanging.
      port.postMessage({ id, ok: false, error: toWire(err) } satisfies Reply);
    }
  }

  return {
    serve(port: MessagePort): void {
      port.on('message', (call: Call) => {
        tail = tail.then(() => run(port, call));
      });
      port.once('close', () => port.removeAllListeners('message'));
      port.postMessage({ shape } satisfies Hello);
    },
  };
}

/** A `Storage` whose every method is a request over `port` to a `createStorageServer`.
 *  Resolves once the server has said which methods exist. */
export function connectStorage(port: MessagePort): Promise<Storage> {
  const pending = new Map<number, { resolve: (v: unknown) => void; reject: (e: Error) => void }>();
  let nextId = 0;
  let closed: Error | null = null;

  const call = (path: string[], args: unknown[]): Promise<unknown> => {
    if (closed) return Promise.reject(closed);
    const id = ++nextId;
    return new Promise((resolve, reject) => {
      pending.set(id, { resolve, reject });
      try {
        port.postMessage({ id, path, args } satisfies Call);
      } catch (err) {
        // e.g. a function among the args: DataCloneError, before anything was sent.
        pending.delete(id);
        reject(err instanceof Error ? err : new Error(String(err)));
      }
    });
  };

  const build = (shape: Shape, path: string[]): Record<string, unknown> => {
    const out: Record<string, unknown> = {};
    for (const [key, sub] of Object.entries(shape)) {
      out[key] = sub === true ? (...args: unknown[]) => call([...path, key], args) : build(sub, [...path, key]);
    }
    return out;
  };

  return new Promise((resolve, reject) => {
    port.on('message', (msg: Hello | Reply) => {
      if ('shape' in msg) {
        resolve(build(msg.shape, []) as unknown as Storage);
        return;
      }
      const entry = pending.get(msg.id);
      if (!entry) return;
      pending.delete(msg.id);
      if (msg.ok) entry.resolve(msg.value);
      else entry.reject(fromWire(msg.error));
    });
    port.once('close', () => {
      closed = new Error('storage connection closed');
      for (const entry of pending.values()) entry.reject(closed);
      pending.clear();
      reject(closed);
    });
  });
}
