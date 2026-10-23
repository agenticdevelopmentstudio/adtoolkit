import { appendFileSync } from 'node:fs';
import { vi } from 'vitest';

// Opt-in (SQL_CAPTURE=<file>): every statement any test sends to libSQL is appended to
// <file> as one JSON line, so tools/audit_query_plans.py can EXPLAIN what the stores
// actually run. A no-op without the variable: the factory hands back the real module.
// (`vi.mock` is hoisted above any `if`, so the check has to live INSIDE the factory.)

/** The innermost non-test source frame that sent the statement (`<package>/src/<file>:<line>`),
 *  or null when only test code is on the stack — a fixture's own setup SQL, not the service's. */
function callSite(): string | null {
  const limit = Error.stackTraceLimit;
  Error.stackTraceLimit = 100; // drizzle's own frames alone exceed V8's default 10
  const stack = new Error().stack ?? '';
  Error.stackTraceLimit = limit;
  for (const frame of stack.split('\n').slice(1)) {
    const m = frame.match(/packages\/([^/]+)\/(src\/[^:)]+:\d+)/);
    if (m && !m[2].includes('/vendor/')) return `${m[1]}/${m[2]}`;
  }
  return null;
}

vi.mock('@libsql/client', async (importOriginal) => {
  const real = await importOriginal<typeof import('@libsql/client')>();
  const out = process.env.SQL_CAPTURE;
  if (!out) return real;
  type Stmt = Parameters<import('@libsql/client').Client['execute']>[0];
  const record = (stmt: Stmt | string, args?: unknown) => {
    const s = {
      ...(typeof stmt === 'string' ? { sql: stmt, args: args ?? [] } : { sql: stmt.sql, args: stmt.args ?? [] }),
      site: callSite(),
    };
    appendFileSync(out, JSON.stringify(s, (_k, v) => (typeof v === 'bigint' ? Number(v) : v instanceof Uint8Array ? null : v)) + '\n');
  };
  const wrap = <T extends object>(target: T): T =>
    new Proxy(target, {
      get(t, key, recv) {
        const v = Reflect.get(t, key, recv);
        if (typeof v !== 'function') return v;
        if (key === 'execute')
          return (stmt: Stmt | string, args?: unknown) => {
            record(stmt, args);
            return (v as (...a: unknown[]) => unknown).call(t, stmt, args);
          };
        if (key === 'batch')
          return (stmts: (Stmt | string)[], mode?: unknown) => {
            for (const s of stmts) record(s);
            return (v as (...a: unknown[]) => unknown).call(t, stmts, mode);
          };
        if (key === 'transaction')
          return async (mode?: unknown) => wrap(await (v as (...a: unknown[]) => Promise<object>).call(t, mode));
        return (v as (...a: unknown[]) => unknown).bind(t);
      },
    });
  return { ...real, createClient: (...a: Parameters<typeof real.createClient>) => wrap(real.createClient(...a)) };
});
