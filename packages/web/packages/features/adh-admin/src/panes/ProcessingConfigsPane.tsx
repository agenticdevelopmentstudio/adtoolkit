"use client";

import { useMemo, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { Plus, Pencil, Trash2, Star, StarOff } from "lucide-react";
import {
  useClearDefaultConfigSet,
  useConfigSets,
  useDeleteConfigSet,
  useSetDefaultConfigSet,
  type ConfigSet,
} from "../api/processing";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { Badge } from "@agenticdevelopertoolkit/ui/components/badge";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { ErrorText } from "@agenticdevelopertoolkit/ui/components/error-text";
import { UnsavedChangesGuard } from "@agenticdevelopertoolkit/ui/components/unsaved-changes-guard";
import { FeatureTitle } from "@agentic-toolkit/resource";
import {
  EditableList,
  TypeToConfirmDialog,
  useEditableList,
  type EditableListColumn,
  type EditableListFacet,
} from "../components/editable-list";
import { ConfigSetDialog } from "../processing/ConfigSetDialog";

/**
 * The LLM config sets a processing job can run on — a service (or the node's local LLM), a model
 * and its parameters — and which one is the default for jobs that name none.
 *
 * No key field lives here: a paid provider's API key is an env var on the nodes that run it.
 */

const PROVIDER_BADGE_VARIANT: Record<
  ConfigSet["provider"],
  "accent" | "blue" | "orange" | "neutral"
> = {
  openai: "accent",
  anthropic: "blue",
  gemini: "orange",
  local: "neutral",
};


export function ProcessingConfigsPane({ help }: { help?: ReactNode } = {}) {
  const router = useRouter();
  const sets = useConfigSets();

  const [creating, setCreating] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogDirty, setDialogDirty] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const deleteSet = useDeleteConfigSet();
  const makeDefault = useSetDefaultConfigSet();
  const clearDefault = useClearDefaultConfigSet();

  const rows = useMemo(() => sets.data ?? [], [sets.data]);

  const columns = useMemo<EditableListColumn<ConfigSet>[]>(
    () => [
      {
        key: "name",
        header: "Name",
        width: "16rem",
        value: (s) => s.name,
        render: (s) => (
          <span className="flex items-center gap-2 truncate font-medium text-apt-text" title={s.name}>
            <span className="truncate">{s.name}</span>
            {s.isDefault && <Badge variant="success">Default</Badge>}
          </span>
        ),
      },
      {
        key: "provider",
        header: "Provider",
        width: "8rem",
        value: (s) => s.provider,
        render: (s) => <Badge variant={PROVIDER_BADGE_VARIANT[s.provider]}>{s.provider}</Badge>,
      },
      {
        key: "model",
        header: "Model",
        width: "minmax(0,1fr)",
        value: (s) => s.model,
        render: (s) => (
          <span className="block truncate font-mono text-xs text-apt-text-muted" title={s.model}>
            {s.model}
          </span>
        ),
      },
    ],
    [],
  );

  const facets = useMemo<EditableListFacet<ConfigSet>[]>(
    () => [{ id: "provider", label: "Provider", valuesOf: (s) => [s.provider] }],
    [],
  );

  const list = useEditableList<ConfigSet>({
    rows,
    getRowId: (s) => s.id,
    columns,
    facets,
    initialSort: { key: "name", dir: "asc" },
  });

  const selected = list.selectedRows;
  // Resolved from the LIVE rows so a saved set doesn't leave the dialog reading as dirty.
  const editing = useMemo(() => rows.find((s) => s.id === editingId) ?? null, [rows, editingId]);
  const hasDefault = rows.some((s) => s.isDefault);

  async function run(action: () => Promise<unknown>) {
    setActionError(null);
    try {
      await action();
    } catch (e) {
      setActionError(errorMessage(e));
    }
  }

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle
        title="Processing Configs"
        api={{
          method: "GET",
          path: "/processing/admin/config-sets",
          pathValues: {},
          title: "Processing config sets API",
        }}
        help={help}
      />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto px-6 pb-8 pt-2">
        <p className="mb-2 max-w-2xl text-sm text-apt-text-muted">
          The LLM a processing job runs on: a service (or the node's local LLM), a model and its
          parameters. The default set is used by jobs that name none.
        </p>
        <p className="mb-6 max-w-2xl text-sm text-apt-text-muted">
          A paid config set runs only on nodes that hold that provider's key
          (AI_NODE_&lt;PROVIDER&gt;_API_KEY).
        </p>

        {actionError && (
          <div className="mb-3">
            <ErrorText error={actionError} />
          </div>
        )}

        <EditableList<ConfigSet>
          list={list}
          ariaLabel="Config sets"
          loading={sets.isLoading}
          error={sets.error}
          errorTitle="Couldn't load config sets"
          columnWidthsKey="admin-processing-configs"
          describeRow={(s) => s.name}
          searchPlaceholder="Name, provider or model"
          emptyLabel="No config sets yet."
          emptyFilteredLabel="No config sets match these filters."
          actions={
            <>
              <Button size="sm" variant="ghost" onClick={() => setCreating(true)}>
                <Plus data-icon="inline-start" />
                New
              </Button>
              <Button
                size="sm"
                variant="ghost"
                disabled={selected.length !== 1}
                onClick={() => {
                  setEditingId(selected[0]!.id);
                  setDialogOpen(true);
                }}
              >
                <Pencil data-icon="inline-start" />
                Edit
              </Button>
              <Button
                size="sm"
                variant="ghost"
                disabled={selected.length !== 1 || selected[0]!.isDefault}
                onClick={() => void run(() => makeDefault.mutateAsync(selected[0]!.id))}
              >
                <Star data-icon="inline-start" />
                Make default
              </Button>
              <Button
                size="sm"
                variant="ghost"
                disabled={!hasDefault}
                onClick={() => void run(() => clearDefault.mutateAsync())}
              >
                <StarOff data-icon="inline-start" />
                Clear default
              </Button>
              <Button
                size="sm"
                variant="destructive-ghost"
                disabled={selected.length !== 1}
                onClick={() => setConfirmDelete(true)}
              >
                <Trash2 data-icon="inline-start" />
                Delete
              </Button>
            </>
          }
        />

        <UnsavedChangesGuard when={dialogDirty} onNavigate={(href) => router.push(href)} />

        <ConfigSetDialog
          key={creating ? "create" : (editingId ?? "closed")}
          open={creating || (dialogOpen && editing !== null)}
          configSet={creating ? null : editing}
          onClose={() => {
            setCreating(false);
            setDialogOpen(false);
          }}
          onDirtyChange={setDialogDirty}
        />

        <TypeToConfirmDialog
          open={confirmDelete}
          title="Delete this config set?"
          description={<>{selected[0]?.name} will be removed. Jobs pinned to it will fall back to the default set.</>}
          confirmValue="delete"
          valueNoun="word"
          confirmLabel="Delete"
          busy={deleteSet.isPending}
          error={deleteSet.error ? errorMessage(deleteSet.error) : undefined}
          onCancel={() => {
            deleteSet.reset();
            setConfirmDelete(false);
          }}
          onConfirm={() =>
            void deleteSet.mutateAsync(selected[0]!.id).then(
              () => {
                setConfirmDelete(false);
                list.clearSelection();
              },
              () => undefined, // the dialog shows the server's message via deleteSet.error
            )
          }
        />
      </div>
    </div>
  );
}
