#!/usr/bin/env python3
"""EXPLAIN every SQL statement the test suites ran and report each one that scans a table.

Capture first, then audit:

    SQL_CAPTURE=/tmp/sql.jsonl pnpm test
    SQL_CAPTURE=/tmp/sql.jsonl pnpm test:int
    python3 tools/audit_query_plans.py /tmp/sql.jsonl [--json]

Plans come from libSQL itself — the `@libsql/client` this package runs on, driven through
node — over a schema built from src/libsql/migrations (the same files prod ran). Not
Python's sqlite3: its SQLite is years newer than libSQL's and plans some statements
differently, so a clean audit there would prove nothing about the database thread.

A statement "scans" when its plan has `SCAN <table>` for a real table — `SCAN t USING
COVERING INDEX i` still reads every entry of `i`. Three kinds of scan are bounded and are
reported but not failed:

  * a scan of a PARTIAL index reads only the rows its WHERE admits, which is the point of
    it (`idx_deploy_inflight` holds the handful of in-flight rows);
  * a TOP-N read — a SELECT with no WHERE that walks an index in ORDER BY order with a
    LIMIT and no sort step — stops after LIMIT entries;
  * a table in ALLOWLIST is operator-sized configuration: its row count is what someone
    typed into the Config screens, not history that grows with time, so reading all of it
    is the least work its callers can do. Each entry says why.

Scans of CTEs, subquery results and the like are not table reads and are ignored.

Each captured line carries the `src/` call site that sent it. A statement only test code
sent (a fixture seeding rows, a test reading them back) is not the service's query, so it
is counted but never judged.

Exit status: 0 when nothing scans outside the bounded kinds, 1 when something does, 2 on a
usage error.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

PKG = Path(__file__).resolve().parent.parent
MIGRATIONS = PKG / "src" / "libsql" / "migrations"

SKIP = re.compile(r"^\s*(create|drop|alter|pragma|begin|commit|rollback|savepoint|release|explain)\b", re.I)
MIGRATION_TABLE = "__drizzle_migrations"
SCAN = re.compile(r"^SCAN (\S+)(?: USING (?:COVERING )?INDEX (\S+))?")
TOP_N = re.compile(r"^\s*select\b(?!.*\bwhere\b).*\border by\b.*\blimit\b", re.I | re.S)

ALLOWLIST: dict[str, str] = {
    "users": "operator accounts — a handful of rows",
    "api_tokens": "tokens an operator minted — tens of rows",
    "site_groups": "Config ▸ Sites groups — operator-entered",
    "monitored_sites": "Config ▸ Sites — operator-entered, one per site",
    "monitored_endpoints": "Config ▸ Sites endpoints — operator-entered, the roster itself",
    "peers": "Config ▸ Peers — operator-entered",
    "peer_snapshots": "one row per peer, overwritten each poll",
    "deploy_integrations": "Config ▸ Platforms — one row per platform token",
    "deploy_project_meta": "one row per deploy project the tokens can see, overwritten each refresh",
    "ignored_deploy_projects": "projects an operator dismissed — operator-entered",
    "platform_health_state": "one row per provider (vercel, railway, …), overwritten each probe",
    "vercel_prod_state": "one row per Vercel project, overwritten each sync",
}

# Runs inside the package so `@libsql/client` resolves to the one the service ships with.
EXPLAINER = r"""
import { createClient } from "@libsql/client";
const input = JSON.parse(await new Promise((ok) => {
  let s = ""; process.stdin.on("data", (d) => (s += d)); process.stdin.on("end", () => ok(s));
}));
const db = createClient({ url: ":memory:" });
for (const stmt of input.schema) await db.execute(stmt);
const master = (await db.execute("select type, name, tbl_name, sql from sqlite_master")).rows;
const version = (await db.execute("select sqlite_version() as v")).rows[0].v;
const plans = [];
for (const q of input.queries) {
  try {
    const r = await db.execute({ sql: "explain query plan " + q.sql, args: q.args });
    plans.push({ plan: r.rows.map((row) => row.detail) });
  } catch (e) {
    plans.push({ error: String(e?.message ?? e) });
  }
}
process.stdout.write(JSON.stringify({ version, master, plans }));
"""


def migration_statements() -> list[str]:
    out = []
    for f in sorted(MIGRATIONS.glob("*.sql")):
        out += [s for s in f.read_text().split("--> statement-breakpoint") if s.strip()]
    return out


def statement_shape(sql: str) -> str:
    """One key per statement SHAPE: collapse whitespace and variable-length `?` lists."""
    s = re.sub(r"\s+", " ", sql).strip()
    s = re.sub(r"\?(?:\s*,\s*\?)+", "?…", s)
    return re.sub(r"\((?:\?…|\?)\)(?:\s*,\s*\((?:\?…|\?)\))+", "(…)", s)


def bind_value(v):
    if isinstance(v, bool):
        return int(v)
    if isinstance(v, (dict, list)):
        return json.dumps(v)
    return v


def bind_args(args):
    if isinstance(args, dict):
        return {k.lstrip(":@$"): bind_value(v) for k, v in args.items()}
    return [bind_value(a) for a in args]


def explain_in_libsql(queries: list[dict]) -> dict:
    payload = json.dumps({"schema": migration_statements(), "queries": queries})
    run = subprocess.run(
        ["node", "--input-type=module", "-e", EXPLAINER],
        cwd=PKG, input=payload, capture_output=True, text=True, check=False,
    )
    if run.returncode != 0:
        sys.exit(f"libsql explainer failed:\n{run.stderr}")
    return json.loads(run.stdout)


def collect(capture: Path) -> tuple[dict[str, dict], int]:
    seen: dict[str, dict] = {}
    fixtures = 0
    for line in capture.read_text().splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        sql = row["sql"]
        if SKIP.match(sql) or MIGRATION_TABLE in sql:
            continue
        if not row.get("site"):
            fixtures += 1
            continue
        key = statement_shape(sql)
        entry = seen.setdefault(key, {"count": 0, "example": sql, "args": row.get("args") or [], "sites": set()})
        entry["count"] += 1
        entry["sites"].add(row["site"])
    return seen, fixtures


def classify(detail: str, sql: str, real: set[str], partial: set[str]) -> tuple[str, str] | None:
    """(kind, table) for a plan line that reads a whole table or index, else None."""
    m = SCAN.match(detail)
    if not m or m.group(1) not in real:
        return None
    table, index = m.group(1), m.group(2)
    if index and index in partial:
        return "partial-index", table
    if index and TOP_N.match(sql):
        return "top-n", table
    if table in ALLOWLIST:
        return "allowlisted", table
    return "scan", table


def audit_capture(capture: Path) -> dict:
    seen, fixtures = collect(capture)
    keys = list(seen)
    out = explain_in_libsql([{"sql": seen[k]["example"], "args": bind_args(seen[k]["args"])} for k in keys])
    real = {r["name"] for r in out["master"] if r["type"] == "table"} - {MIGRATION_TABLE}
    partial = {r["name"] for r in out["master"] if r["type"] == "index" and r["sql"] and re.search(r"\bWHERE\b", r["sql"], re.I)}

    scans, bounded, errors, clean = [], [], [], 0
    for key, res in zip(keys, out["plans"]):
        e = seen[key]
        if "error" in res:
            errors.append({"sql": key, "error": res["error"]})
            continue
        kinds = [(d, c) for d in res["plan"] if (c := classify(d, key, real, partial))]
        if not kinds:
            clean += 1
            continue
        report = {
            "tables": sorted({t for _d, (_k, t) in kinds}),
            "kinds": sorted({k for _d, (k, _t) in kinds}),
            "plan": [d for d, _c in kinds],
            "count": e["count"],
            "sites": sorted(e["sites"]),
            "sql": key,
        }
        (scans if "scan" in report["kinds"] else bounded).append(report)
    scans.sort(key=lambda s: (s["tables"], s["sql"]))
    bounded.sort(key=lambda s: (s["kinds"], s["tables"], s["sql"]))
    per_table: dict[str, int] = defaultdict(int)
    for s in scans:
        for t in s["tables"]:
            per_table[t] += 1
    return {
        "sqlite_version": out["version"],
        "statements": len(seen),
        "fixture_statements": fixtures,
        "clean": clean,
        "bounded": len(bounded),
        "scanning": len(scans),
        "per_table": dict(sorted(per_table.items())),
        "scans": scans,
        "bounded_reads": bounded,
        "allowlist": ALLOWLIST,
        "errors": errors,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("capture", type=Path, help="JSONL written by SQL_CAPTURE")
    ap.add_argument("--json", action="store_true", help="emit the full report as JSON")
    ap.add_argument("--bounded", action="store_true", help="also list the bounded reads")
    a = ap.parse_args()
    if not a.capture.is_file():
        print(f"no capture file: {a.capture}", file=sys.stderr)
        return 2
    r = audit_capture(a.capture)
    if a.json:
        print(json.dumps(r, indent=1))
    else:
        print(
            f"libSQL {r['sqlite_version']} · {r['statements']} distinct statements · {r['clean']} index-only · "
            f"{r['bounded']} bounded · {r['scanning']} scan a table · {len(r['errors'])} unexplainable"
        )
        for t, n in r["per_table"].items():
            print(f"  {t}: {n}")
        for s in r["scans"]:
            print(f"\n[{', '.join(s['tables'])}] ×{s['count']}  {' | '.join(s['plan'])}")
            print(f"  from {', '.join(s['sites'])}\n  {s['sql'][:400]}")
        if a.bounded:
            for s in r["bounded_reads"]:
                print(f"\n({'/'.join(s['kinds'])}) [{', '.join(s['tables'])}]  {' | '.join(s['plan'])}")
                print(f"  from {', '.join(s['sites'])}\n  {s['sql'][:200]}")
        for e in r["errors"]:
            print(f"\n[unexplainable] {e['error']}\n  {e['sql'][:300]}")
    return 1 if r["scanning"] or r["errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
