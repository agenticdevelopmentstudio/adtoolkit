"use client";

import { useEffect, useMemo, useRef, useState, type FormEvent } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@agenticdevelopertoolkit/ui/components/dialog";
import { DialogActions } from "@agenticdevelopertoolkit/ui/components/dialog-actions";
import { UnsavedChangesAlert } from "@agenticdevelopertoolkit/ui/components/unsaved-changes-alert";
import { Input } from "@agenticdevelopertoolkit/ui/components/input";
import { Select } from "@agenticdevelopertoolkit/ui/components/select";
import { Textarea } from "@agenticdevelopertoolkit/ui/components/textarea";
import { Field } from "@agenticdevelopertoolkit/ui/blocks/field";
import { FieldGroup } from "@agenticdevelopertoolkit/ui/blocks/field-group";
import { useAction } from "@agenticdevelopertoolkit/ui/hooks/useAction";
import { ErrorText } from "@agenticdevelopertoolkit/ui/components/error-text";
import { useSaveConfigSet, type ConfigSet } from "../api/processing";
import {
  LOCAL_SERVICE,
  buildConfigSetInput,
  formBlockedReason,
  stateFromConfigSet,
  withService,
  type ConfigSetFormState,
  type OutputModeChoice,
} from "./config-set-form";
import { useConfigSetServices } from "./useConfigSetServices";

/** The kinds a node can run (the backend rejects any other); `external` and the like are not. */
const RUNNABLE_KINDS: ReadonlySet<string> = new Set(["openai", "anthropic", "gemini"]);

/** A service's model list as the picker sees it: the column is jsonb, so an entry may be a bare
 *  string or an object with an `id` (and optionally a `displayName`). */
function modelOptions(models: readonly unknown[] | undefined): { id: string; label: string }[] {
  const out: { id: string; label: string }[] = [];
  for (const m of models ?? []) {
    if (typeof m === "string") out.push({ id: m, label: m });
    else if (m && typeof (m as { id?: unknown }).id === "string") {
      const { id, displayName } = m as { id: string; displayName?: string };
      out.push({ id, label: displayName ?? id });
    }
  }
  return out;
}

/**
 * Create/edit form for one processing config set.
 *
 * A set with no service is the node's own LLM (its model is the free-text Ollama model name); a
 * set with a service picks that service's model. The dialog never touches an API key: a paid
 * set uses the key stored on its personas service, which the backend refuses if it has none.
 */
export function ConfigSetDialog({
  open,
  configSet,
  onClose,
  onDirtyChange,
}: {
  open: boolean;
  /** The set being edited, or null in create mode. */
  configSet: ConfigSet | null;
  onClose: () => void;
  /** Reports whether the form holds unsaved input, so the page's guard covers it. */
  onDirtyChange: (dirty: boolean) => void;
}) {
  const saveSet = useSaveConfigSet();
  const save = useAction();
  const { items: ownServices } = useConfigSetServices();
  const services = useMemo(
    () => (ownServices ?? []).filter((s) => RUNNABLE_KINDS.has(s.providerKind)),
    [ownServices],
  );
  // Config sets are global but the picker lists only the signed-in admin's own services. A set
  // built on someone else's (or a shared) service would otherwise render as "local"; keep its
  // service selectable, with an unknown model list (so the model is free text).
  const foreignService =
    configSet?.service && !services.some((s) => s.id === configSet.service!.id)
      ? configSet.service
      : null;
  const initial = useMemo(() => stateFromConfigSet(configSet), [configSet]);
  const [form, setForm] = useState<ConfigSetFormState>(initial);
  const formRef = useRef<HTMLFormElement>(null);
  const [confirmingClose, setConfirmingClose] = useState(false);

  const patch = (p: Partial<ConfigSetFormState>) => setForm((f) => ({ ...f, ...p }));

  const activeService = useMemo(
    () => services.find((s) => s.id === form.serviceId) ?? null,
    [services, form.serviceId],
  );
  const options = useMemo(() => modelOptions(activeService?.models), [activeService]);
  // Free text for the local LLM, and for a service that lists no models (the backend accepts any
  // model then); a select only when the service has a known list to choose from.
  const modelIsSelect = activeService !== null && options.length > 0;
  // Only an OpenAI-compatible service has a choice to make; every other kind always uses its own
  // schema constraint, and the local LLM takes a schema natively.
  const speaksOpenAI =
    activeService?.providerKind === "openai" ||
    (foreignService !== null && form.serviceId === foreignService.id && configSet?.provider === "openai");

  const dirty = useMemo(() => JSON.stringify(form) !== JSON.stringify(initial), [form, initial]);
  useEffect(() => onDirtyChange(open && dirty), [open, dirty, onDirtyChange]);
  const blockedReason = useMemo(() => formBlockedReason(form), [form]);
  const canSave = dirty && blockedReason === null;

  function close() {
    if (save.busy) return;
    if (dirty) {
      setConfirmingClose(true);
      return;
    }
    onClose();
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    void save.run(async () => {
      const blocked = formBlockedReason(form);
      if (blocked) throw new Error(blocked);
      await saveSet.mutateAsync({ id: configSet?.id, input: buildConfigSetInput(form) });
      onClose();
    });
  }

  return (
    <Dialog open={open} onOpenChange={(next) => !next && close()}>
      <DialogContent className="max-w-xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{configSet ? "Edit config set" : "New config set"}</DialogTitle>
          <DialogDescription>
            Which LLM a processing job runs on, and with what parameters. Leave the service on the
            node's local LLM to run on the node's own Ollama.
          </DialogDescription>
        </DialogHeader>
        <form ref={formRef} onSubmit={handleSubmit} className="flex flex-col gap-4">
          <Field label="Name">
            <Input
              aria-label="Name"
              value={form.name}
              onChange={(e) => patch({ name: e.target.value })}
              disabled={save.busy}
              placeholder="e.g. Claude fast"
            />
          </Field>
          <Field label="Description">
            <Textarea
              aria-label="Description"
              value={form.description}
              onChange={(e) => patch({ description: e.target.value })}
              disabled={save.busy}
            />
          </Field>
          <Field
            label="Service"
            hint="Where the model runs: one of your personas services (OpenAI, Anthropic, Gemini, or an OpenAI-compatible host such as Groq, Cerebras, Fireworks or Together), or the node's own Ollama."
          >
            <Select
              aria-label="Service"
              value={form.serviceId}
              onChange={(e) => setForm((f) => withService(f, e.target.value))}
            >
              <option value={LOCAL_SERVICE}>Node's local LLM</option>
              {foreignService && (
                <option value={foreignService.id}>
                  {foreignService.name} (not in your services)
                </option>
              )}
              {services.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </Select>
          </Field>
          <Field
            label="Model"
            hint={modelIsSelect ? undefined : "The model name as the node's Ollama knows it."}
          >
            {modelIsSelect ? (
              <Select
                aria-label="Model"
                value={form.model}
                onChange={(e) => patch({ model: e.target.value })}
              >
                <option value="">No model selected</option>
                {options.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.label}
                  </option>
                ))}
              </Select>
            ) : (
              <Input
                aria-label="Model"
                value={form.model}
                onChange={(e) => patch({ model: e.target.value })}
                placeholder="e.g. llama3.2"
                className="font-mono"
              />
            )}
          </Field>
          {speaksOpenAI && (
            <Field
              label="Output mode"
              hint="How the node asks for JSON. Automatic follows the model's catalog entry; pick JSON mode for a model that rejects a response schema."
            >
              <Select
                aria-label="Output mode"
                value={form.outputMode}
                onChange={(e) => patch({ outputMode: e.target.value as OutputModeChoice })}
              >
                <option value="">Automatic</option>
                <option value="schema">Structured output (JSON schema)</option>
                <option value="json">JSON mode (schema in the prompt)</option>
              </Select>
            </Field>
          )}
          <FieldGroup title="Parameters">
            <div className="flex flex-col gap-3 sm:flex-row">
              <Field
                label="Temperature"
                className="flex-1"
                hint="0 to 2. Clear it for reasoning models, which reject it."
              >
                <Input
                  aria-label="Temperature"
                  type="number"
                  step="0.1"
                  min={0}
                  max={2}
                  value={form.temperature}
                  onChange={(e) => patch({ temperature: e.target.value })}
                />
              </Field>
              <Field label="Max output tokens" className="flex-1">
                <Input
                  aria-label="Max output tokens"
                  type="number"
                  min={1}
                  max={200000}
                  value={form.maxOutputTokens}
                  onChange={(e) => patch({ maxOutputTokens: e.target.value })}
                />
              </Field>
              <Field label="Timeout (seconds)" className="flex-1" hint="1 to 600">
                <Input
                  aria-label="Timeout (seconds)"
                  type="number"
                  min={1}
                  max={600}
                  value={form.timeoutSeconds}
                  onChange={(e) => patch({ timeoutSeconds: e.target.value })}
                />
              </Field>
            </div>
          </FieldGroup>
          {save.error ? (
            <ErrorText error={save.error} />
          ) : (
            blockedReason &&
            dirty && (
              <p className="text-sm text-apt-text-muted" role="status">
                {blockedReason}
              </p>
            )
          )}
          {/* Lets Enter submit; see ProviderTemplateDialog for why it carries the same gate. */}
          <button
            type="submit"
            className="hidden"
            aria-hidden
            tabIndex={-1}
            disabled={!canSave || save.busy}
          />
        </form>
        <DialogActions
          cancelLabel="Cancel"
          onCancel={close}
          confirmLabel="Save"
          onConfirm={() => formRef.current?.requestSubmit()}
          busy={save.busy}
          confirmDisabled={!canSave}
          focusOnMount={false}
        />
        <UnsavedChangesAlert
          open={confirmingClose}
          onDiscard={() => {
            setConfirmingClose(false);
            onClose();
          }}
          onStay={() => setConfirmingClose(false)}
        />
      </DialogContent>
    </Dialog>
  );
}
