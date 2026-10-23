import { describe, it, expect } from 'vitest';
import { MessageChannel } from 'node:worker_threads';
import { connectStorage, createStorageServer } from '../src/storage/remote';
import type { Storage } from '../src/storage/ports';

// The transport alone, over an in-thread MessageChannel, against a fake Storage: the
// real libSQL one is covered by storage-thread.int.test.ts.
async function over(fake: object): Promise<Storage> {
  const { port1, port2 } = new MessageChannel();
  createStorageServer(fake as Storage).serve(port1);
  return connectStorage(port2);
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe('storage over a MessagePort', () => {
  it('round-trips args and results, Dates included', async () => {
    const storage = await over({
      health: { echo: async (a: unknown, b: unknown) => ({ a, b, at: new Date(0) }) },
    });
    const out = await (storage.health as unknown as { echo: (a: unknown, b: unknown) => Promise<unknown> }).echo(1, ['x']);
    expect(out).toEqual({ a: 1, b: ['x'], at: new Date(0) });
  });

  it('reaches nested stores like telemetry.errors', async () => {
    const storage = await over({ telemetry: { errors: { load: async () => [{ id: 'e1' }] } } });
    expect(await storage.telemetry.errors.load()).toEqual([{ id: 'e1' }]);
  });

  it('keeps an error message, code and cause chain', async () => {
    const storage = await over({
      auth: {
        createUser: async () => {
          const driver = Object.assign(new Error('UNIQUE constraint failed: users.email'), { code: 'SQLITE_CONSTRAINT_UNIQUE' });
          throw new Error('Failed query: insert into users', { cause: driver });
        },
      },
    });
    const err = await storage.auth.createUser({} as never).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(Error);
    expect((err as Error).message).toBe('Failed query: insert into users');
    const cause = (err as Error).cause as Error & { code?: string };
    expect(cause.message).toBe('UNIQUE constraint failed: users.email');
    expect(cause.code).toBe('SQLITE_CONSTRAINT_UNIQUE');
  });

  it('runs calls one at a time, in arrival order, across ports', async () => {
    const log: string[] = [];
    const fake = {
      health: {
        slow: async () => {
          log.push('slow:start');
          await sleep(30);
          log.push('slow:end');
        },
        fast: async () => {
          log.push('fast');
        },
      },
    } as unknown as Storage;
    const server = createStorageServer(fake);
    const a = new MessageChannel();
    const b = new MessageChannel();
    server.serve(a.port1);
    server.serve(b.port1);
    const [sa, sb] = await Promise.all([connectStorage(a.port2), connectStorage(b.port2)]);
    type T = { slow: () => Promise<void>; fast: () => Promise<void> };
    await Promise.all([(sa.health as unknown as T).slow(), (sb.health as unknown as T).fast()]);
    expect(log).toEqual(['slow:start', 'slow:end', 'fast']);
    a.port2.close();
    b.port2.close();
  });

  it('rejects an argument the structured clone cannot carry', async () => {
    const storage = await over({ maintenance: { snapshotIfDue: async () => ({ created: false }) } });
    await expect(storage.maintenance.snapshotIfDue({ now: () => 1 })).rejects.toThrow();
  });

  it('rejects pending calls when the server side closes', async () => {
    const { port1, port2 } = new MessageChannel();
    createStorageServer({ health: { hang: () => new Promise(() => {}) } } as unknown as Storage).serve(port1);
    const storage = await connectStorage(port2);
    const pending = (storage.health as unknown as { hang: () => Promise<void> }).hang();
    port1.close();
    await expect(pending).rejects.toThrow('storage connection closed');
  });
});
