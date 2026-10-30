"use client";
import { ISSUE_SOURCES, isIssueSource, type IssueSource } from "../lib/issue-sources";
import { usePersistedState } from "./use-persisted-state";

const decodeSources = (raw: unknown): Set<IssueSource> | undefined =>
  Array.isArray(raw) ? new Set(raw.filter((s): s is IssueSource => typeof s === "string" && isIssueSource(s))) : undefined;

/**
 * The source-set toggle state shared by every filtered pane (active problems,
 * recently resolved, activity). Starts with all sources selected; toggling one
 * adds/removes it. Extracted so the three panes can't drift in how they filter.
 * Persisted per pane under `storageKey`, so each pane's choice survives a reload.
 */
export function useSourceFilter(storageKey: string): {
  sources: Set<IssueSource>;
  toggleSource: (s: IssueSource) => void;
} {
  const [sources, setSources] = usePersistedState<Set<IssueSource>>(
    storageKey,
    new Set(ISSUE_SOURCES),
    decodeSources,
    (v) => [...v],
  );
  const toggleSource = (s: IssueSource): void =>
    setSources((prev) => {
      const next = new Set(prev);
      if (next.has(s)) next.delete(s);
      else next.add(s);
      return next;
    });
  return { sources, toggleSource };
}
