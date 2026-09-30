"use client";

import { useEffect, useMemo, useRef, useState, type FormEvent } from "react";
import { CalendarX, Pencil, Plus, Trash2 } from "lucide-react";
import { useAction } from "@agenticdevelopertoolkit/ui/hooks/useAction";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { Input } from "@agenticdevelopertoolkit/ui/components/input";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@agenticdevelopertoolkit/ui/components/dialog";
import { DialogActions } from "@agenticdevelopertoolkit/ui/components/dialog-actions";
import { Field } from "@agenticdevelopertoolkit/ui/blocks";
import { formatMicros } from "@agenticdevelopertoolkit/ui/lib/money";
import {
  EditableList,
  useEditableList,
  type EditableListColumn,
} from "../components/editable-list";
import {
  useCreateFixedCost,
  useDeleteFixedCost,
  useFixedCosts,
  useUpdateFixedCost,
  type FixedCost,
  type UpdateFixedCostBody,
} from "../api/insight";
import { dollarsToMicros, microsToDollars } from "./decimal";
import { todayUtc } from "./days";

/** A row that has started has already priced days, so the backend refuses to re-price it. */
export const hasStarted = (cost: FixedCost, today: string = todayUtc()): boolean =>
  cost.effectiveFrom < today;

type Draft = {
  provider: string;
  label: string;
  dollars: string;
  from: string;
  to: string;
  note: string;
};

const blankDraft = (): Draft => ({
  provider: "",
  label: "",
  dollars: "",
  from: todayUtc(),
  to: "",
  note: "",
});

const draftOf = (cost: FixedCost): Draft => ({
  provider: cost.provider,
  label: cost.label,
  dollars: microsToDollars(cost.monthlyMicros),
  from: cost.effectiveFrom,
  to: cost.effectiveTo ?? "",
  note: cost.note,
});

/**
 * Creates a fixed cost, or edits one. A cost that has started can only change its label, its end
 * date and its note — the amount, provider and start are what days were already priced with, and
 * the backend answers 409 to any of them — so those are not offered, only shown.
 */
export function FixedCostDialog({
  cost,
  open,
  onClose,
}: {
  /** The cost being edited, or null to create one. */
  cost: FixedCost | null;
  open: boolean;
  onClose: () => void;
}) {
  const createCost = useCreateFixedCost();
  const updateCost = useUpdateFixedCost();
  const save = useAction();
  const formRef = useRef<HTMLFormElement>(null);
  const initial = useMemo(() => (cost ? draftOf(cost) : blankDraft()), [cost]);
  const [form, setForm] = useState<Draft>(initial);
  const locked = cost !== null && hasStarted(cost);
  const set = (change: Partial<Draft>) => setForm((prev) => ({ ...prev, ...change }));

  // What the form would send, or why it cannot be sent (shown beside the amount).
  const amount = dollarsToMicros(form.dollars);
  // A label is required on an edit too: the backend would store the blank one the create refuses.
  const problem =
    cost === null && (form.provider.trim() === "" || form.label.trim() === "")
      ? "Provider and label are required."
      : form.label.trim() === ""
        ? "A label is required."
        : !locked && !amount.ok
        ? amount.message
        : form.to !== "" && form.to < form.from
          ? "The end date is before the start."
          : null;
  const changes = (): UpdateFixedCostBody => {
    const out: UpdateFixedCostBody = {};
    if (form.label.trim() !== initial.label) out.label = form.label.trim();
    if (form.note !== initial.note) out.note = form.note;
    if (form.to !== initial.to) out.effectiveTo = form.to === "" ? null : form.to;
    if (!locked) {
      if (form.dollars !== initial.dollars && amount.ok) out.monthlyMicros = amount.value;
      if (form.from !== initial.from) out.effectiveFrom = form.from;
    }
    return out;
  };
  const dirty = cost === null || Object.keys(changes()).length > 0;
  const canSave = dirty && problem === null;

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!canSave) return;
    void save.run(async () => {
      if (cost) {
        await updateCost.mutateAsync({ id: cost.id, changes: changes() });
      } else {
        await createCost.mutateAsync({
          provider: form.provider.trim(),
          label: form.label.trim(),
          monthlyMicros: (amount as { value: number }).value,
          effectiveFrom: form.from,
          ...(form.to !== "" ? { effectiveTo: form.to } : {}),
          ...(form.note !== "" ? { note: form.note } : {}),
        });
      }
      onClose();
    });
  }

  const close = () => {
    if (!save.busy) onClose();
  };

  return (
    <Dialog open={open} onOpenChange={(next) => !next && close()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{cost ? "Edit fixed cost" : "New fixed cost"}</DialogTitle>
          <DialogDescription>
            {locked
              ? `${cost.provider} — ${formatMicros(cost.monthlyMicros)} a month from ${cost.effectiveFrom}. It has started, so only its label, end date and note can change; to change the amount, end it and add a new one.`
              : "A monthly amount, prorated by day over the days it is in effect."}
          </DialogDescription>
        </DialogHeader>
        <form ref={formRef} onSubmit={handleSubmit} className="flex flex-col gap-4">
          {!locked && (
            <Field label="Provider">
              <Input
                aria-label="Provider"
                value={form.provider}
                onChange={(e) => set({ provider: e.target.value })}
                disabled={cost !== null}
              />
            </Field>
          )}
          <Field label="Label">
            <Input
              aria-label="Label"
              value={form.label}
              onChange={(e) => set({ label: e.target.value })}
            />
          </Field>
          {!locked && (
            <Field
              label="Monthly amount (dollars)"
              error={form.dollars !== "" && !amount.ok ? amount.message : undefined}
            >
              <Input
                aria-label="Monthly amount (dollars)"
                value={form.dollars}
                onChange={(e) => set({ dollars: e.target.value })}
                inputMode="decimal"
                className="text-right tabular-nums"
              />
            </Field>
          )}
          <div className="grid grid-cols-2 gap-4">
            {!locked && (
              <Field label="From">
                <Input
                  type="date"
                  aria-label="From"
                  value={form.from}
                  onChange={(e) => set({ from: e.target.value })}
                />
              </Field>
            )}
            <Field label="To (last day charged)">
              <Input
                type="date"
                aria-label="To"
                value={form.to}
                onChange={(e) => set({ to: e.target.value })}
              />
            </Field>
          </div>
          <Field label="Note" error={save.error ?? undefined}>
            <Input
              aria-label="Note"
              value={form.note}
              onChange={(e) => set({ note: e.target.value })}
            />
          </Field>
          {!save.error && dirty && problem && (
            <p className="text-sm text-apt-text-muted" role="status">
              {problem}
            </p>
          )}
          <button type="submit" className="hidden" aria-hidden tabIndex={-1} disabled={!canSave || save.busy} />
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
      </DialogContent>
    </Dialog>
  );
}

/** The fixed monthly costs: add one, edit one, or end one (sets its last charged day). */
export function FixedCostsList() {
  const { data, isLoading, error } = useFixedCosts();
  const updateCost = useUpdateFixedCost();
  const deleteCost = useDeleteFixedCost();
  const ending = useAction();
  const [dialog, setDialog] = useState<{ cost: FixedCost | null } | null>(null);

  const columns = useMemo<EditableListColumn<FixedCost>[]>(
    () => [
      {
        key: "provider",
        header: "Provider",
        width: "10rem",
        value: (c) => c.provider,
        render: (c) => <span className="text-sm text-apt-text">{c.provider}</span>,
      },
      {
        key: "label",
        header: "Label",
        value: (c) => c.label,
        render: (c) => <span className="text-sm text-apt-text">{c.label}</span>,
      },
      {
        key: "monthly",
        header: "Monthly",
        width: "8rem",
        align: "end",
        value: (c) => c.monthlyMicros,
        render: (c) => <span className="tabular-nums text-sm">{formatMicros(c.monthlyMicros)}</span>,
      },
      {
        key: "from",
        header: "From",
        width: "7rem",
        value: (c) => c.effectiveFrom,
        render: (c) => <span className="tabular-nums text-sm text-apt-text-muted">{c.effectiveFrom}</span>,
      },
      {
        key: "to",
        header: "To",
        width: "7rem",
        value: (c) => c.effectiveTo,
        render: (c) => (
          <span className="tabular-nums text-sm text-apt-text-muted">{c.effectiveTo ?? "ongoing"}</span>
        ),
      },
      {
        key: "note",
        header: "Note",
        value: (c) => c.note,
        render: (c) => <span className="truncate text-sm text-apt-text-muted">{c.note}</span>,
      },
    ],
    [],
  );

  const list = useEditableList<FixedCost>({
    rows: data,
    getRowId: (c) => c.id,
    columns,
    initialSort: { key: "from", dir: "desc" },
  });

  const selected = list.selectedRows.length === 1 ? list.selectedRows[0]! : null;
  const today = todayUtc();
  // A cost that has not begun cannot be "ended" without still charging its first day, so it is
  // deleted instead — the backend allows re-pricing and deleting while `effectiveFrom >= today`, so
  // one starting today counts as not begun. One that is running and open-ended is ended: its last
  // charged day is today.
  const notBegun = selected !== null && !hasStarted(selected, today);
  const canEnd = selected !== null && !notBegun && selected.effectiveTo === null;
  // The action's failure belongs to the row it was about: choosing another row clears it.
  const [showEndingError, setShowEndingError] = useState(false);
  const selectedId = selected?.id ?? null;
  useEffect(() => setShowEndingError(false), [selectedId]);
  const act = (action: () => Promise<void>) => {
    setShowEndingError(true);
    void ending.run(action);
  };
  const endCost = (cost: FixedCost) =>
    act(async () => {
      await updateCost.mutateAsync({ id: cost.id, changes: { effectiveTo: today } });
      list.clearSelection();
    });
  const removeCost = (cost: FixedCost) =>
    act(async () => {
      await deleteCost.mutateAsync(cost.id);
      list.clearSelection();
    });

  return (
    <>
      <EditableList<FixedCost>
        list={list}
        ariaLabel="Fixed costs"
        loading={isLoading}
        error={error}
        errorTitle="Couldn't load the fixed costs"
        columnWidthsKey="admin-costs-fixed"
        describeRow={(c) => `${c.provider} ${c.label}`}
        searchPlaceholder="Provider or label"
        emptyLabel="No fixed costs."
        emptyFilteredLabel="No fixed costs match."
        actions={
          <>
            <Button size="sm" variant="ghost" onClick={() => setDialog({ cost: null })}>
              <Plus data-icon="inline-start" />
              New
            </Button>
            <Button
              size="sm"
              variant="ghost"
              disabled={selected === null}
              onClick={() => setDialog({ cost: selected })}
            >
              <Pencil data-icon="inline-start" />
              Edit
            </Button>
            {notBegun ? (
              <Button
                size="sm"
                variant="ghost"
                disabled={ending.busy}
                onClick={() => removeCost(selected)}
              >
                <Trash2 data-icon="inline-start" />
                Delete
              </Button>
            ) : (
              <Button
                size="sm"
                variant="ghost"
                disabled={!canEnd || ending.busy}
                onClick={() => canEnd && endCost(selected)}
              >
                <CalendarX data-icon="inline-start" />
                End cost
              </Button>
            )}
            {/* A failed end/delete is about the action, not the list, so it sits by the action
                (cleared by the next attempt or another selection) instead of in the list's
                "couldn't load" slot. */}
            {ending.error && showEndingError && (
              <span role="alert" className="text-sm text-apt-red">
                {ending.error}
              </span>
            )}
          </>
        }
      />
      {dialog && (
        <FixedCostDialog
          key={dialog.cost?.id ?? "new"}
          cost={dialog.cost}
          open
          onClose={() => setDialog(null)}
        />
      )}
    </>
  );
}
