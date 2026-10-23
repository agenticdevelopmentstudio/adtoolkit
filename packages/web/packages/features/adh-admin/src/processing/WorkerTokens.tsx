"use client";

import { useMemo, useState, type FormEvent } from "react";
import { useQueryClient } from "@tanstack/react-query";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@agenticdevelopertoolkit/ui/components/dialog";
import { AlertModal } from "@agenticdevelopertoolkit/ui/components/alert-modal";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { CopyButton } from "@agenticdevelopertoolkit/ui/components/copy-button";
import { DialogErrorText, ErrorText } from "@agenticdevelopertoolkit/ui/components/error-text";
import { Input } from "@agenticdevelopertoolkit/ui/components/input";
import { Field } from "@agenticdevelopertoolkit/ui/blocks/field";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { ListBarActions, useBulkRemove } from "@agentic-toolkit/resource";
import {
  EditableList,
  useEditableList,
  type EditableListColumn,
} from "../components/editable-list";
import { formatRelativeTime } from "../llm-providers/sync-format";
import {
  processingKeys,
  revokeWorkerToken,
  useCreateWorkerToken,
  useWorkerTokens,
  type WorkerToken,
} from "../api/processing";

/** The env var a node reads its token from (websites/ai-node and the Swift daemon alike). */
export const WORKER_TOKEN_ENV = "AI_NODE_API_TOKEN";

/**
 * The tokens AI nodes authenticate with. Each one carries only the `ai-processing:worker` scope, so
 * it can claim and report jobs and nothing else. The raw value is returned once, by the create, and
 * this dialog is the only place it is ever drawn; revoking one makes every node using it get 401.
 */
export function WorkerTokens() {
  const qc = useQueryClient();
  const tokens = useWorkerTokens();
  const create = useCreateWorkerToken();

  const [createOpen, setCreateOpen] = useState(false);
  const [name, setName] = useState("");
  const [minted, setMinted] = useState<string | null>(null);
  // Escape or a backdrop click on the reveal would otherwise drop a secret nobody can show again.
  const [confirmingDrop, setConfirmingDrop] = useState(false);

  const revoke = useBulkRemove<WorkerToken>({
    getId: (t) => t.id,
    remove: revokeWorkerToken,
    onSettled: () => void qc.invalidateQueries({ queryKey: processingKeys.workerTokens() }),
    onDone: () => list.clearSelection(),
    errorMessage: (err) => errorMessage(err),
  });

  const columns = useMemo<EditableListColumn<WorkerToken>[]>(
    () => [
      {
        key: "name",
        header: "Name",
        width: "12rem",
        value: (t) => t.name,
        render: (t) => <span className="truncate font-medium text-apt-text">{t.name}</span>,
      },
      {
        key: "prefix",
        header: "Prefix",
        width: "9rem",
        value: (t) => t.prefix,
        render: (t) => (
          <code className="truncate font-mono text-xs text-apt-text-muted">{t.prefix}…</code>
        ),
      },
      {
        key: "nodes",
        header: "Used by",
        width: "minmax(0,1fr)",
        value: (t) => t.nodes.join(", "),
        render: (t) => (
          <span className="truncate font-mono text-xs text-apt-text-muted">
            {t.nodes.length ? t.nodes.join(", ") : "No node yet"}
          </span>
        ),
      },
      {
        key: "createdAt",
        header: "Created",
        width: "9rem",
        searchable: false,
        value: (t) => t.createdAt,
        render: (t) => <span title={t.createdAt}>{formatRelativeTime(t.createdAt)}</span>,
      },
      {
        key: "lastUsedAt",
        header: "Last used",
        width: "9rem",
        searchable: false,
        value: (t) => t.lastUsedAt ?? "",
        render: (t) =>
          t.lastUsedAt ? (
            <span title={t.lastUsedAt}>{formatRelativeTime(t.lastUsedAt)}</span>
          ) : (
            <span className="text-apt-text-muted">Never</span>
          ),
      },
    ],
    [],
  );

  const list = useEditableList<WorkerToken>({
    rows: tokens.data ?? [],
    getRowId: (t) => t.id,
    columns,
    initialSort: { key: "createdAt", dir: "desc" },
  });
  const selected = list.selectedRows;

  function openCreate() {
    setName("");
    setMinted(null);
    create.reset();
    setCreateOpen(true);
  }

  function closeCreate() {
    if (create.isPending) return;
    setCreateOpen(false);
    setMinted(null);
  }

  function requestClose() {
    if (minted !== null) setConfirmingDrop(true);
    else closeCreate();
  }

  const canCreate = name.trim() !== "" && !create.isPending;
  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!canCreate) return;
    create.mutate({ name: name.trim() }, { onSuccess: (created) => setMinted(created.token) });
  }

  return (
    <section aria-label="Worker tokens" className="mb-6 flex flex-col gap-2">
      <h2 className="text-sm font-medium text-apt-text">Worker tokens</h2>
      <p className="max-w-2xl text-sm text-apt-text-muted">
        A node signs in to the backend with one of these, set as{" "}
        <code className="font-mono">{WORKER_TOKEN_ENV}</code> on its deployment. A token can only
        claim and report processing jobs. Revoking one signs out every node using it.
      </p>
      <EditableList<WorkerToken>
        list={list}
        ariaLabel="Worker tokens"
        loading={tokens.isLoading}
        error={tokens.error}
        errorTitle="Couldn't load worker tokens"
        columnWidthsKey="admin-ai-worker-tokens"
        describeRow={(t) => t.name}
        searchPlaceholder="Name, prefix or node"
        emptyLabel="No worker tokens yet. Create one for each deployed node."
        emptyFilteredLabel="No worker tokens match this search."
        actions={
          <ListBarActions
            noun="worker token"
            addLabel="New"
            deleteLabel="Revoke"
            selectedCount={selected.length}
            onAdd={openCreate}
            onDelete={() => revoke.open(selected)}
          />
        }
      />

      <Dialog open={createOpen} onOpenChange={(open) => !open && requestClose()}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{minted ? "Worker token created" : "New worker token"}</DialogTitle>
            <DialogDescription>
              {minted
                ? `Copy it now; it won't be shown again. Set it as ${WORKER_TOKEN_ENV} on the node.`
                : "Name it after the node or environment that will use it."}
            </DialogDescription>
          </DialogHeader>
          {minted ? (
            <div className="flex flex-col gap-4">
              <div className="flex items-center gap-2">
                <Input
                  aria-label="Worker token"
                  readOnly
                  value={minted}
                  className="font-mono text-xs"
                  onFocus={(e) => e.currentTarget.select()}
                />
                <CopyButton label="Copy worker token" getText={() => minted} />
              </div>
              <DialogFooter>
                <Button type="button" size="sm" onClick={closeCreate}>
                  Done
                </Button>
              </DialogFooter>
            </div>
          ) : (
            <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
              <Field label="Name">
                <Input
                  aria-label="Name"
                  value={name}
                  maxLength={100}
                  disabled={create.isPending}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. railway-staging"
                />
              </Field>
              {create.error && <ErrorText error={errorMessage(create.error)} />}
              <DialogFooter>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  disabled={create.isPending}
                  onClick={closeCreate}
                >
                  Cancel
                </Button>
                <Button type="submit" size="sm" disabled={!canCreate}>
                  {create.isPending ? "Creating…" : "Create token"}
                </Button>
              </DialogFooter>
            </form>
          )}
          <AlertModal
            open={confirmingDrop}
            tone="error"
            title="Close without copying?"
            description="This token won't be shown again. If you haven't copied it, revoke it and create another."
            confirmLabel="Close"
            cancelLabel="Keep open"
            onConfirm={() => {
              setConfirmingDrop(false);
              closeCreate();
            }}
            onCancel={() => setConfirmingDrop(false)}
          />
        </DialogContent>
      </Dialog>

      <AlertModal
        open={revoke.targets != null}
        tone="error"
        title={
          revoke.targets && revoke.targets.length > 1
            ? `Revoke ${revoke.targets.length} worker tokens?`
            : "Revoke worker token?"
        }
        description={
          revoke.targets ? (
            <>
              <span>
                {`Revoke ${revoke.targets.map((t) => t.name).join(", ")}? Every node using ${
                  revoke.targets.length === 1 ? "it" : "them"
                } stops getting jobs immediately.`}
              </span>
              <DialogErrorText error={revoke.error} />
            </>
          ) : undefined
        }
        confirmLabel="Revoke"
        confirmVariant="destructive"
        cancelLabel="Cancel"
        busy={revoke.pending}
        onConfirm={revoke.confirm}
        onCancel={revoke.cancel}
      />
    </section>
  );
}
