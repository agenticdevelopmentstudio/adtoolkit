import { createRequire } from "node:module";
import { MessageChannel, Worker, type MessagePort } from "node:worker_threads";
import type { Storage } from "../storage/ports";
import { connectStorage } from "../storage/remote";
import type { LibsqlConnection } from "./client";

// Main-thread handle to the database thread (storage-worker.ts). The host calls
// startStorageThread once at boot instead of opening a connection itself; from then on
// no thread but that one touches the database file, and every other thread, the API
// and the monitor worker alike, gets the Storage port as a client over a MessagePort.

export interface StorageWorkerData {
  db: LibsqlConnection;
}

export interface StorageWorkerRequest {
  attach: MessagePort;
}

export type StorageWorkerReply = { ready: true } | { ready: false; error: string };

export interface StorageThread {
  /** The Storage port for THIS thread. */
  storage: Storage;
  /** A fresh port for another thread (transfer it), served by the same queue. */
  connect(): MessagePort;
}

/** Spawn the database thread, wait for it to tune + migrate, and connect this thread.
 *  `onExit` fires if the database thread dies: every pending and later call then
 *  rejects, so the host should treat it as fatal. */
export async function startStorageThread(
  conn: LibsqlConnection,
  opts: { onExit: (reason: string) => void },
): Promise<StorageThread> {
  // Resolved through this package's `exports`, never a relative path, so the entry is
  // always the BUILT dist — same reason as MonitorWorkerClient.spawn.
  const entry = createRequire(import.meta.url).resolve("@agentic-toolkit/status-server/storage-worker");
  const worker = new Worker(entry, { workerData: { db: conn } satisfies StorageWorkerData });

  await new Promise<void>((resolve, reject) => {
    worker.once("message", (msg: StorageWorkerReply) => {
      if (msg.ready) resolve();
      else reject(new Error(`storage thread failed to start: ${msg.error}`));
    });
    worker.once("error", reject);
  });
  worker.on("error", (err: Error) => opts.onExit(`storage thread crashed: ${err.message}`));
  worker.on("exit", (code) => opts.onExit(`storage thread exited (${code})`));

  const connect = (): MessagePort => {
    const { port1, port2 } = new MessageChannel();
    worker.postMessage({ attach: port1 } satisfies StorageWorkerRequest, [port1]);
    return port2;
  };

  return { storage: await connectStorage(connect()), connect };
}
