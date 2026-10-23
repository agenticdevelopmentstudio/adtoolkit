import { parentPort, workerData, type MessagePort } from "node:worker_threads";
import { migrateDb, openLibsql, tuneDbForConcurrency, type LibsqlConnection } from "./client";
import { createLibsqlStorage } from "./index";
import { createStorageServer } from "../storage/remote";
import type { StorageWorkerData, StorageWorkerReply, StorageWorkerRequest } from "./storage-thread";

// The database thread: the ONE connection to the file, owned here, and every Storage
// call from every other thread queued through it (see ../storage/remote.ts for why).
// Glue only — spawn and attach policy live in storage-thread.ts.

const port = parentPort;
if (!port) throw new Error("storage worker must be spawned via worker_threads (see storage-thread.ts)");

const { db: conn } = (workerData ?? {}) as Partial<StorageWorkerData>;
if (!conn?.url) throw new Error("storage worker spawned without workerData.db.url (see StorageWorkerData)");

try {
  const db = openLibsql(conn as LibsqlConnection);
  await tuneDbForConcurrency(db, conn);
  await migrateDb(db); // embedded-file deployments self-migrate on boot
  const server = createStorageServer(createLibsqlStorage(db, conn));
  port.on("message", (msg: StorageWorkerRequest) => server.serve(msg.attach as MessagePort));
  port.postMessage({ ready: true } satisfies StorageWorkerReply);
} catch (err) {
  port.postMessage({ ready: false, error: err instanceof Error ? err.message : String(err) } satisfies StorageWorkerReply);
}
