import { describe, it, expect } from 'vitest';
import { execFile } from 'node:child_process';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import { isUniqueViolation } from '../src/storage/ports';

/** Rebuild the reported message chain as an Error + cause chain. */
const chainToError = (chain: (string | undefined)[]): Error | undefined =>
  chain.reduceRight<Error | undefined>((cause, msg) => (msg === undefined ? cause : new Error(msg, { cause })), undefined);

// The real database thread, spawned from the BUILT dist exactly as a host spawns it,
// so it runs in a bare-node child (see worker-boot.int.test.ts for why the test
// runner's own resolver can't be used): it migrates a fresh file, serves the host
// thread and a second port through one queue, and carries driver errors back intact
// enough for isUniqueViolation to recognise them; a monitor worker given only a
// storage port completes a cycle through it.
describe('storage thread under bare node', () => {
  it('migrates, serves two ports, and carries driver errors intact', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'storage-thread-'));
    const driver = fileURLToPath(new URL('./helpers/storage-thread-driver.mjs', import.meta.url));
    const { NODE_OPTIONS: _omitted, ...env } = process.env;
    const { stdout } = await promisify(execFile)(process.execPath, [driver, `file:${join(dir, 'status.db')}`], {
      env,
      timeout: 60_000,
    });
    const line = stdout.split('\n').find((l) => l.startsWith('RESULT:'));
    expect(line, `no RESULT line\n${stdout}`).toBeDefined();
    const result = JSON.parse(line!.slice('RESULT:'.length)) as { dupChain: string[] } & Record<string, unknown>;
    expect(result).toMatchObject({ email: 'a@b.com', createdAtIsDate: true, foundSame: true, cycle: 'ok', exits: [] });
    expect(isUniqueViolation(chainToError(result.dupChain))).toBe(true);
  }, 90_000);
});
