// Starts the database thread from the package's BUILT dist under bare node — the
// conditions of a production host — and exercises it from two ports. Run by
// storage-thread.int.test.ts as a child process (vitest's resolver would hand back the
// TypeScript source), including a monitor worker that holds no connection of its own;
// prints RESULT:<json> and exits 0, or exits non-zero on failure.
import { connectStorage, envConfig, MonitorWorkerClient } from "@agentic-toolkit/status-server";
import { startStorageThread } from "@agentic-toolkit/status-server/libsql";

const [url] = process.argv.slice(2);
if (!url) {
  console.error("usage: node storage-thread-driver.mjs <file:url>");
  process.exit(2);
}

const exits = [];
const thread = await startStorageThread({ url }, { onExit: (reason) => exits.push(reason) });
const user = await thread.storage.auth.createUser({ email: "A@B.com", displayName: "A", role: "viewer" });
const other = await connectStorage(thread.connect());
const found = await other.auth.findUserByEmail("a@b.com");
const dup = await other.auth.createUser({ email: "a@b.com", displayName: "A", role: "viewer" }).catch((e) => e);

const monitor = new MonitorWorkerClient({
  cycleTimeoutMs: 30_000,
  workerData: { config: envConfig(process.env) },
  storagePort: thread.connect,
});
const cycle = await monitor.runCycle(false).then(() => "ok", (e) => e.message);

console.log(
  `RESULT:${JSON.stringify({
    email: user.email,
    createdAtIsDate: user.createdAt instanceof Date,
    foundSame: found?.id === user.id,
    // The chain isUniqueViolation walks: the drizzle wrapper, then the driver error.
    dupChain: [dup?.message, dup?.cause?.message],
    cycle,
    exits,
  })}`,
);
process.exit(0);
