"use client";

import { useMemo, useRef, useState, type FormEvent } from "react";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { Input } from "@agenticdevelopertoolkit/ui/components/input";
import { Select } from "@agenticdevelopertoolkit/ui/components/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@agenticdevelopertoolkit/ui/components/dialog";
import { DialogActions } from "@agenticdevelopertoolkit/ui/components/dialog-actions";
import { Field } from "@agenticdevelopertoolkit/ui/blocks";
import { useCreateRate, type InsightItem } from "../api/insight";
import { todayUtc } from "./days";
import { PRICE_BASES, shiftDecimal, toMicrosPerUnit, type PriceBasis } from "./decimal";

type CreateRateBody = Parameters<ReturnType<typeof useCreateRate>["mutateAsync"]>[0];

/** The rate in effect for `key` (the latest start among the item's rates for it), if any. */
function currentRate(item: InsightItem, key: string) {
  return item.rates
    .filter((r) => r.quantityKey === key)
    .sort((a, b) => b.effectiveFrom.localeCompare(a.effectiveFrom))[0];
}

type KeyDraft = { text: string; basis: PriceBasis };

/**
 * Sets the price of one cost item: a per-unit rate for each of its quantity keys, effective from a
 * day (today by default). A rate is a NEW row, never a rewrite of a past price, so this always
 * creates; a key left as it was prefilled is not re-sent. The backend's 409 (a rate already
 * starts that day, or the row is past) is shown under the key it came from.
 */
export function SetPriceDialog({
  item,
  open,
  onClose,
}: {
  item: InsightItem | null;
  open: boolean;
  onClose: () => void;
}) {
  const createRate = useCreateRate();
  const keys = useMemo(() => (item ? Object.keys(item.quantities).sort() : []), [item]);

  const [drafts, setDrafts] = useState<Record<string, KeyDraft>>(() =>
    Object.fromEntries(
      keys.map((key) => [
        key,
        { text: item ? (currentRate(item, key)?.microsPerUnit ?? "") : "", basis: "micros-per-unit" },
      ]),
    ),
  );
  const [effectiveFrom, setEffectiveFrom] = useState(todayUtc);
  const [saved, setSaved] = useState<ReadonlySet<string>>(new Set());
  const [failure, setFailure] = useState<{ key: string; message: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const formRef = useRef<HTMLFormElement>(null);

  // What each key would send: nothing (blank, unchanged, or already saved), a value, or a field error.
  const plan = keys.map((key) => {
    const draft = drafts[key] ?? { text: "", basis: "micros-per-unit" as const };
    const prefilled = item ? currentRate(item, key)?.microsPerUnit : undefined;
    if (saved.has(key) || draft.text.trim() === "") {
      return { key, send: null, error: null as string | null };
    }
    const converted = toMicrosPerUnit(draft.text, draft.basis);
    if (!converted.ok) return { key, send: null, error: converted.message };
    if (prefilled !== undefined && shiftDecimal(prefilled, 0) === converted.value) {
      return { key, send: null, error: null };
    }
    return { key, send: converted.value, error: null };
  });
  const toSend = plan.filter((p) => p.send !== null);
  const blocked = plan.some((p) => p.error !== null) || effectiveFrom === "";
  const canSave = toSend.length > 0 && !blocked && !busy;

  const setDraft = (key: string, change: Partial<KeyDraft>) =>
    setDrafts((prev) => ({ ...prev, [key]: { ...prev[key]!, ...change } }));

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!item || !canSave) return;
    setBusy(true);
    setFailure(null);
    const done = new Set(saved);
    try {
      for (const { key, send } of toSend) {
        const body: CreateRateBody = {
          category: item.category as CreateRateBody["category"],
          provider: item.provider,
          sku: item.sku,
          quantityKey: key,
          microsPerUnit: send!,
          effectiveFrom,
        };
        try {
          await createRate.mutateAsync(body);
        } catch (err) {
          setFailure({ key, message: errorMessage(err) });
          return;
        }
        done.add(key);
      }
      onClose();
    } finally {
      // Keys that landed before a failure are not sent again on the retry.
      setSaved(done);
      setBusy(false);
    }
  }

  const close = () => {
    if (!busy) onClose();
  };

  return (
    <Dialog open={open && item !== null} onOpenChange={(next) => !next && close()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Set price</DialogTitle>
          <DialogDescription>
            {item ? `${item.category} / ${item.provider} / ${item.sku}` : ""} — a price per unit
            for each quantity, effective from the day below. It re-prices every day from then on.
          </DialogDescription>
        </DialogHeader>
        <form ref={formRef} onSubmit={handleSubmit} className="flex flex-col gap-4">
          {plan.map(({ key, error }) => {
            const draft = drafts[key]!;
            const message = error ?? (failure?.key === key ? failure.message : undefined);
            return (
              <Field key={key} label={<span className="font-mono">{key}</span>} error={message}>
                <div className="flex gap-2">
                  <Input
                    aria-label={`${key} price`}
                    value={draft.text}
                    onChange={(e) => setDraft(key, { text: e.target.value })}
                    disabled={saved.has(key)}
                    inputMode="decimal"
                    placeholder="blank to leave unpriced"
                    className="text-right tabular-nums"
                  />
                  <Select
                    aria-label={`${key} price unit`}
                    value={draft.basis}
                    onChange={(e) => setDraft(key, { basis: e.target.value as PriceBasis })}
                    className="w-44"
                  >
                    {PRICE_BASES.map((b) => (
                      <option key={b.id} value={b.id}>
                        {b.label}
                      </option>
                    ))}
                  </Select>
                </div>
              </Field>
            );
          })}
          <Field label="Effective from">
            <Input
              type="date"
              aria-label="Effective from"
              value={effectiveFrom}
              onChange={(e) => setEffectiveFrom(e.target.value)}
            />
          </Field>
          {/* Enter submits through this; the visible confirm below requests the same submit. */}
          <button type="submit" className="hidden" aria-hidden tabIndex={-1} disabled={!canSave} />
        </form>
        <DialogActions
          cancelLabel="Cancel"
          onCancel={close}
          confirmLabel="Save"
          onConfirm={() => formRef.current?.requestSubmit()}
          busy={busy}
          confirmDisabled={!canSave}
          focusOnMount={false}
        />
      </DialogContent>
    </Dialog>
  );
}
