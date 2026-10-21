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

export const EMPTY_FORM: ConfigSetFormState = {
  name: "",
  description: "",
  serviceId: LOCAL_SERVICE,
  model: "",
  temperature: "",
  maxOutputTokens: "",
  timeoutSeconds: "",
};

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
