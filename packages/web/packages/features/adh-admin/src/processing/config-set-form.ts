import type { ConfigSet, ConfigSetInput } from "../api/processing";

// Pure form <-> wire conversion for the config-set dialog, split out so the rules (blank number
// = omitted, timeout in seconds on screen and milliseconds on the wire) are testable without a DOM.

/** Sentinel for the service select's first option: no service = the node's local LLM. */
export const LOCAL_SERVICE = "";

export interface ConfigSetFormState {
  name: string;
  description: string;
  serviceId: string;
  model: string;
  temperature: string;
  maxOutputTokens: string;
  timeoutSeconds: string;
}

type TierParams = Pick<ConfigSetFormState, "temperature" | "maxOutputTokens" | "timeoutSeconds">;

/**
 * What a new set starts with, per tier. Today's jobs (categorize and tag) want a short, repeatable
 * JSON answer: a low temperature and a modest token cap. A node's Ollama on a CPU container is
 * slow, worst on the first call while the model loads; a paid API answers in seconds.
 */
export const TIER_DEFAULTS: { local: TierParams; paid: TierParams } = {
  local: { temperature: "0.2", maxOutputTokens: "512", timeoutSeconds: "300" },
  paid: { temperature: "0.2", maxOutputTokens: "1024", timeoutSeconds: "60" },
};

const tierDefaults = (serviceId: string): TierParams =>
  serviceId === LOCAL_SERVICE ? TIER_DEFAULTS.local : TIER_DEFAULTS.paid;

export const EMPTY_FORM: ConfigSetFormState = {
  name: "",
  description: "",
  serviceId: LOCAL_SERVICE,
  model: "",
  ...TIER_DEFAULTS.local,
};

/**
 * The form after the service changes to `serviceId`. The model belongs to the old service, so it
 * clears. Each parameter still holding the old tier's default takes the new tier's; one the admin
 * changed (or an existing set's stored value that differs) stays.
 */
export function withService(f: ConfigSetFormState, serviceId: string): ConfigSetFormState {
  const from = tierDefaults(f.serviceId);
  const to = tierDefaults(serviceId);
  const next: ConfigSetFormState = { ...f, serviceId, model: "" };
  for (const k of Object.keys(to) as (keyof TierParams)[]) {
    if (f[k] === from[k]) next[k] = to[k];
  }
  return next;
}

export function stateFromConfigSet(set: ConfigSet | null): ConfigSetFormState {
  if (!set) return EMPTY_FORM;
  const { temperature, maxOutputTokens, timeoutMs } = set.params;
  return {
    name: set.name,
    description: set.description ?? "",
    serviceId: set.service?.id ?? LOCAL_SERVICE,
    model: set.model,
    temperature: temperature === undefined ? "" : String(temperature),
    maxOutputTokens: maxOutputTokens === undefined ? "" : String(maxOutputTokens),
    timeoutSeconds: timeoutMs === undefined ? "" : String(timeoutMs / 1000),
  };
}

/** Why the form can't be saved (null = it can). Ranges mirror the backend's param schema. */
export function formBlockedReason(f: ConfigSetFormState): string | null {
  if (!f.name.trim()) return "A name is required.";
  if (!f.model.trim()) return "A model is required.";
  const t = f.temperature.trim();
  if (t && !(Number(t) >= 0 && Number(t) <= 2)) return "Temperature must be between 0 and 2.";
  const m = f.maxOutputTokens.trim();
  if (m && !(Number.isInteger(Number(m)) && Number(m) >= 1 && Number(m) <= 200000)) {
    return "Max output tokens must be a whole number from 1 to 200000.";
  }
  const s = f.timeoutSeconds.trim();
  if (s && !(Number(s) >= 1 && Number(s) <= 600)) return "Timeout must be between 1 and 600 seconds.";
  return null;
}

export function buildConfigSetInput(f: ConfigSetFormState): ConfigSetInput {
  const params: NonNullable<ConfigSetInput["params"]> = {};
  if (f.temperature.trim()) params.temperature = Number(f.temperature);
  if (f.maxOutputTokens.trim()) params.maxOutputTokens = Number(f.maxOutputTokens);
  if (f.timeoutSeconds.trim()) params.timeoutMs = Math.round(Number(f.timeoutSeconds) * 1000);
  return {
    name: f.name.trim(),
    description: f.description.trim() || null,
    serviceId: f.serviceId === LOCAL_SERVICE ? null : f.serviceId,
    model: f.model.trim(),
    params,
  };
}
