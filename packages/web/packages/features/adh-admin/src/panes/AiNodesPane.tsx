"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import { Trash2 } from "lucide-react";
import {
  useDeleteNode,
  useNodes,
  useProcessingSettings,
  usePutProcessingSettings,
  type ProcessingNode,
} from "../api/processing";
import { Badge } from "@agenticdevelopertoolkit/ui/components/badge";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { ErrorText } from "@agenticdevelopertoolkit/ui/components/error-text";
import { Input } from "@agenticdevelopertoolkit/ui/components/input";
import { FeatureTitle } from "@agentic-toolkit/resource";
import {
  EditableList,
  TypeToConfirmDialog,
  useEditableList,
  type EditableListColumn,
  type EditableListFacet,
} from "../components/editable-list";
import { formatRelativeTime } from "../llm-providers/sync-format";
import { NodeLogs } from "../processing/NodeLogs";
import { RETENTION_ERROR, parseRetentionDays } from "../processing/retention";


/** How long node logs are kept — one setting for the whole fleet. */
function RetentionStrip() {
  const settings = useProcessingSettings();
  const put = usePutProcessingSettings();
  const stored = settings.data?.logRetentionDays;
  const [text, setText] = useState("");
  // Follow the stored value until the admin starts typing over it; after that a background
  // refetch (another operator saved) must not replace what is in the box.
  const [touched, setTouched] = useState(false);
  useEffect(() => {
    if (stored !== undefined && !touched) setText(String(stored));
  }, [stored, touched]);

  const days = parseRetentionDays(text);
  const invalid = text !== "" && days === null;
  const canSave = days !== null && days !== stored && !put.isPending;

  return (
    <div className="mb-4 flex flex-col gap-1">
      <div className="flex items-end gap-2">
        <label className="flex flex-col gap-1 text-sm text-apt-text-muted">
          Log retention (days)
          <Input
            aria-label="Log retention (days)"
            type="number"
            min={1}
            max={365}
            step={1}
            className="w-32"
            value={text}
            onChange={(e) => {
              put.reset();
              setTouched(true);
              setText(e.target.value);
            }}
          />
        </label>
        <Button
          size="sm"
          variant="secondary"
          disabled={!canSave}
          onClick={() =>
            days !== null &&
            put.mutate({ logRetentionDays: days }, { onSuccess: () => setTouched(false) })
          }
        >
          Save retention
        </Button>
      </div>
      {invalid && (
        <p className="text-sm text-apt-text-muted" role="status">
          {RETENTION_ERROR}
        </p>
      )}
      {settings.error && <ErrorText error={errorMessage(settings.error)} />}
      {put.error && <ErrorText error={errorMessage(put.error)} />}
    </div>
  );
}

function NodeDetail({ node }: { node: ProcessingNode }) {
  const entries = Object.entries(node.config);
  return (
    <div className="flex flex-col gap-4 p-3">
      <section aria-label="Reported config">
        <h3 className="mb-1 text-sm font-medium text-apt-text">Reported config</h3>
        {entries.length === 0 ? (
          <p className="text-sm text-apt-text-muted">Nothing reported.</p>
        ) : (
          <dl className="grid grid-cols-[max-content_1fr] gap-x-4 gap-y-1 text-sm">
            {entries.map(([k, v]) => (
              <div key={k} className="contents">
                <dt className="font-mono text-xs text-apt-text-muted">{k}</dt>
                <dd className="break-all font-mono text-xs text-apt-text">
                  {typeof v === "string" ? v : JSON.stringify(v)}
                </dd>
              </div>
            ))}
          </dl>
        )}
      </section>
      <NodeLogs key={node.id} nodeId={node.id} />
    </div>
  );
}

/** The deployed AI processing nodes: who is online, what they ran, their config and their logs. */
export function AiNodesPane({ help }: { help?: ReactNode } = {}) {
  const nodes = useNodes();
  const deleteNode = useDeleteNode();
  const [confirmDelete, setConfirmDelete] = useState(false);

  const rows = useMemo(() => nodes.data ?? [], [nodes.data]);

  const columns = useMemo<EditableListColumn<ProcessingNode>[]>(
    () => [
      {
        key: "id",
        header: "Node",
        width: "14rem",
        value: (n) => n.id,
        render: (n) => (
          <span className="block truncate font-mono text-xs font-medium text-apt-text" title={n.id}>
            {n.id}
          </span>
        ),
      },
      { key: "kind", header: "Kind", width: "7rem", value: (n) => n.kind },
      { key: "version", header: "Version", width: "7rem", value: (n) => n.version },
      {
        key: "online",
        header: "Status",
        width: "7rem",
        value: (n) => (n.online ? "Online" : "Offline"),
        render: (n) => (
          <Badge variant={n.online ? "success" : "neutral"}>{n.online ? "Online" : "Offline"}</Badge>
        ),
      },
      {
        key: "providers",
        header: "Providers",
        width: "minmax(0,1fr)",
        value: (n) => n.providers.join(", "),
      },
      {
        key: "lastSeenAt",
        header: "Last seen",
        width: "9rem",
        value: (n) => n.lastSeenAt,
        render: (n) => <span title={n.lastSeenAt}>{formatRelativeTime(n.lastSeenAt)}</span>,
      },
      {
        key: "jobs",
        header: "Done / failed",
        width: "8rem",
        align: "end",
        value: (n) => n.jobsCompleted,
        render: (n) => (
          <span className="tabular-nums">{`${n.jobsCompleted} / ${n.jobsFailed}`}</span>
        ),
      },
    ],
    [],
  );

  const facets = useMemo<EditableListFacet<ProcessingNode>[]>(
    () => [
      { id: "status", label: "Status", valuesOf: (n) => [n.online ? "Online" : "Offline"] },
      { id: "kind", label: "Kind", valuesOf: (n) => [n.kind] },
    ],
    [],
  );

  const list = useEditableList<ProcessingNode>({
    rows,
    getRowId: (n) => n.id,
    columns,
    facets,
    initialSort: { key: "lastSeenAt", dir: "desc" },
  });
  const selected = list.selectedRows;

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle
        title="AI Nodes"
        api={{
          method: "GET",
          path: "/processing/admin/nodes",
          pathValues: {},
          title: "Processing nodes API",
        }}
        help={help}
      />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto px-6 pb-8 pt-2">
        <p className="mb-4 max-w-2xl text-sm text-apt-text-muted">
          The processing nodes that have registered with the backend. A node is online when it has
          checked in within the last two minutes. Select one to see what it reported and its logs.
        </p>
        <RetentionStrip />
        <EditableList<ProcessingNode>
          list={list}
          ariaLabel="AI nodes"
          loading={nodes.isLoading}
          error={nodes.error}
          errorTitle="Couldn't load AI nodes"
          columnWidthsKey="admin-ai-nodes"
          describeRow={(n) => n.id}
          searchPlaceholder="Node, kind or provider"
          emptyLabel="No nodes have registered yet."
          emptyFilteredLabel="No nodes match these filters."
          details={{
            label: "Node",
            emptyLabel: "Select a node to see its config and logs.",
            manyLabel: "Select one node to see its config and logs.",
            storageKey: "admin-ai-nodes-detail",
            heightClass: "h-[44rem]",
            render: (n) => <NodeDetail node={n} />,
          }}
          actions={
            <Button
              size="sm"
              variant="destructive-ghost"
              disabled={selected.length !== 1}
              onClick={() => setConfirmDelete(true)}
            >
              <Trash2 data-icon="inline-start" />
              Delete
            </Button>
          }
        />
        <TypeToConfirmDialog
          open={confirmDelete}
          title="Delete this node?"
          description={
            <>
              {selected[0]?.id} will be removed from the registry; its logs are kept until the retention
              window expires. If the node is still running it will register again within a minute.
            </>
          }
          confirmValue="delete"
          valueNoun="word"
          confirmLabel="Delete"
          busy={deleteNode.isPending}
          error={deleteNode.error ? errorMessage(deleteNode.error) : undefined}
          onCancel={() => {
            deleteNode.reset();
            setConfirmDelete(false);
          }}
          onConfirm={() =>
            void deleteNode.mutateAsync(selected[0]!.id).then(
              () => {
                setConfirmDelete(false);
                list.clearSelection();
              },
              () => undefined, // shown in the dialog via deleteNode.error
            )
          }
        />
      </div>
    </div>
  );
}
