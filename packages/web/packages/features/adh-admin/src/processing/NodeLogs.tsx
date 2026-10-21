"use client";

import { useMemo, useState } from "react";
import { Badge } from "@agenticdevelopertoolkit/ui/components/badge";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { ErrorText } from "@agenticdevelopertoolkit/ui/components/error-text";
import { Select } from "@agenticdevelopertoolkit/ui/components/select";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { useNodeLogs, type LogLevel } from "../api/processing";
import { formatDateTime } from "../lib/timestamps";

const LEVELS: LogLevel[] = ["debug", "info", "warn", "error"];

const LEVEL_VARIANT: Record<LogLevel, "neutral" | "blue" | "orange" | "error"> = {
  debug: "neutral",
  info: "blue",
  warn: "orange",
  error: "error",
};

/**
 * One node's log, newest first, filtered by MINIMUM level server-side (the chosen level and
 * everything more severe) and paged with Load more.
 *
 * Hand-rolled rather than the shared `LogPanel` (`@agenticdevelopertoolkit/controls/logging-panel`):
 * that panel is a tail-following console for a live stream, and this is a newest-first list paged
 * backwards through `nextBefore` with per-row level badges, which its follow model does not fit.
 */
export function NodeLogs({ nodeId }: { nodeId: string }) {
  const [level, setLevel] = useState<LogLevel | "">("");
  const logs = useNodeLogs(nodeId, level || undefined);
  const entries = useMemo(() => logs.data?.pages.flatMap((p) => p.entries) ?? [], [logs.data]);

  return (
    <section aria-label="Logs" className="flex flex-col gap-2">
      <div className="flex items-center gap-2">
        <label htmlFor={`level-${nodeId}`} className="text-sm text-apt-text-muted">
          Level
        </label>
        <div className="w-40">
          <Select
            id={`level-${nodeId}`}
            aria-label="Level"
            value={level}
            onChange={(e) => setLevel(e.target.value as LogLevel | "")}
          >
            <option value="">All levels</option>
            {LEVELS.map((l) => (
              <option key={l} value={l}>
                {l === "debug" ? l : `${l} and above`}
              </option>
            ))}
          </Select>
        </div>
      </div>
      {logs.error && <ErrorText error={errorMessage(logs.error)} />}
      {logs.isLoading ? (
        <p className="text-sm text-apt-text-muted">Loading logs…</p>
      ) : entries.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No log entries.</p>
      ) : (
        <ul className="flex flex-col divide-y divide-apt-border text-sm">
          {entries.map((e) => (
            <li key={e.id} className="flex items-baseline gap-3 py-1">
              <span className="w-40 shrink-0 tabular-nums text-xs text-apt-text-dim">
                {formatDateTime(e.occurredAt)}
              </span>
              <Badge variant={LEVEL_VARIANT[e.level]}>{e.level}</Badge>
              <span className="shrink-0 font-mono text-xs text-apt-text-muted">{e.event}</span>
              <span className="min-w-0 flex-1 break-words text-apt-text">{e.message}</span>
              {e.jobId && (
                <span className="shrink-0 font-mono text-xs text-apt-text-dim" title="Job">
                  {e.jobId}
                </span>
              )}
            </li>
          ))}
        </ul>
      )}
      {logs.hasNextPage && (
        <div>
          <Button
            size="sm"
            variant="ghost"
            disabled={logs.isFetchingNextPage}
            onClick={() => void logs.fetchNextPage()}
          >
            Load more
          </Button>
        </div>
      )}
    </section>
  );
}
