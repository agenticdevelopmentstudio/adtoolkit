"use client";

import type { RequestBody, SuccessBody, components } from "@agentic-toolkit/adh-api-types";
import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { authedJson, authedRequest } from "./http";

// ── AI processing: config sets, nodes, logs, retention ──────────────────────
//
// Admin-gated reads and writes over `/processing/admin/*`. Plain functions at the `authedJson`
// boundary plus a key factory; the panes wrap them in react-query. Types are spec-derived so a
// backend change fails this file's tsc. No API key appears anywhere here: paid-provider keys live
// as env vars on the nodes, never in an admin payload.

export type ConfigSet = components["schemas"]["AiProcessingConfigSet"];
export type ConfigSetInput = RequestBody<"/processing/admin/config-sets", "post">;
export type ConfigSetParams = components["schemas"]["AiProcessingConfigSetParams"];
export type ProcessingNode = components["schemas"]["AiProcessingNode"];
export type NodeLog = components["schemas"]["AiProcessingNodeLog"];
export type NodeLogPage = components["schemas"]["AiProcessingNodeLogPage"];
export type LogLevel = NodeLog["level"];
export type ProcessingSettings = components["schemas"]["AiProcessingSettings"];
export type ConfigSetList = SuccessBody<"/processing/admin/config-sets", "get">;
export type NodeList = SuccessBody<"/processing/admin/nodes", "get">;

export interface NodeLogQuery {
  level?: LogLevel;
  before?: number;
  limit?: number;
}

/** Every processing-admin read keys under this prefix (pinned fresh in AdminQueryProvider). */
export const PROCESSING_ADMIN_KEY = ["processing-admin"] as const;

export const processingKeys = {
  configSets: () => [...PROCESSING_ADMIN_KEY, "config-sets"] as const,
  nodes: () => [...PROCESSING_ADMIN_KEY, "nodes"] as const,
  node: (id: string) => [...PROCESSING_ADMIN_KEY, "node", id] as const,
  logs: (id: string, query: Omit<NodeLogQuery, "before"> = {}) =>
    [...PROCESSING_ADMIN_KEY, "logs", id, query] as const,
  settings: () => [...PROCESSING_ADMIN_KEY, "settings"] as const,
};

const BASE = "/api/processing/admin";
const send = (method: string, body?: unknown): RequestInit => ({
  method,
  ...(body === undefined ? {} : { body: JSON.stringify(body) }),
});

export const listConfigSets = () => authedJson<ConfigSetList>(`${BASE}/config-sets`);
export const createConfigSet = (input: ConfigSetInput) =>
  authedJson<ConfigSet>(`${BASE}/config-sets`, send("POST", input));
export const updateConfigSet = (id: string, input: ConfigSetInput) =>
  authedJson<ConfigSet>(`${BASE}/config-sets/${encodeURIComponent(id)}`, send("PUT", input));
// The deletes answer 204 No Content, which `authedJson` rejects as an empty body.
export const deleteConfigSet = (id: string) =>
  authedRequest(`${BASE}/config-sets/${encodeURIComponent(id)}`, send("DELETE"));
export const setDefaultConfigSet = (id: string) =>
  authedJson<ConfigSet>(`${BASE}/config-sets/${encodeURIComponent(id)}/default`, send("POST"));
export const clearDefaultConfigSet = () =>
  authedRequest(`${BASE}/config-sets/default`, send("DELETE"));

export const listNodes = () => authedJson<NodeList>(`${BASE}/nodes`);
export const getNode = (id: string) =>
  authedJson<ProcessingNode>(`${BASE}/nodes/${encodeURIComponent(id)}`);
export const deleteNode = (id: string) =>
  authedRequest(`${BASE}/nodes/${encodeURIComponent(id)}`, send("DELETE"));

export function listNodeLogs(nodeId: string, query: NodeLogQuery = {}) {
  const params = new URLSearchParams();
  if (query.level) params.set("level", query.level);
  if (query.before !== undefined) params.set("before", String(query.before));
  if (query.limit !== undefined) params.set("limit", String(query.limit));
  const qs = params.toString();
  return authedJson<NodeLogPage>(
    `${BASE}/nodes/${encodeURIComponent(nodeId)}/logs${qs ? `?${qs}` : ""}`,
  );
}

export const getProcessingSettings = () => authedJson<ProcessingSettings>(`${BASE}/settings`);
export const putProcessingSettings = (settings: ProcessingSettings) =>
  authedJson<ProcessingSettings>(`${BASE}/settings`, send("PUT", settings));

// ── react-query hooks ───────────────────────────────────────────────────────

export const useConfigSets = () =>
  useQuery({
    queryKey: processingKeys.configSets(),
    queryFn: listConfigSets,
    select: (body) => body.configSets,
  });

/** Create (no `id`) or update (with `id`) one config set. */
export function useSaveConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: { id?: string; input: ConfigSetInput }) =>
      id ? updateConfigSet(id, input) : createConfigSet(input),
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}

export function useDeleteConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: deleteConfigSet,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}

export function useSetDefaultConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: setDefaultConfigSet,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}

export function useClearDefaultConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: clearDefaultConfigSet,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}
