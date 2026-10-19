'use client'

"use client";

// src/help/HelpMasterDetail.tsx
import { useMemo } from "react";
import { useRouter } from "next/navigation";
import { HierarchicalDetailView } from "@agenticdevelopertoolkit/ui/blocks";

// src/help/topic-icons.tsx
import { Braces, FileText, Info, LayoutGrid, Plug } from "lucide-react";
import { jsx } from "react/jsx-runtime";
var TOPIC_ICON = {
  overview: /* @__PURE__ */ jsx(Info, { size: 16, "aria-hidden": true }),
  "rest-api": /* @__PURE__ */ jsx(Braces, { size: 16, "aria-hidden": true }),
  mcp: /* @__PURE__ */ jsx(Plug, { size: 16, "aria-hidden": true }),
  hub: /* @__PURE__ */ jsx(LayoutGrid, { size: 16, "aria-hidden": true })
};
function topicIcon(id) {
  return TOPIC_ICON[id] ?? /* @__PURE__ */ jsx(FileText, { size: 16, "aria-hidden": true });
}

// src/help/HelpMasterDetail.tsx
import { jsx as jsx2 } from "react/jsx-runtime";
function HelpMasterDetail({
  levels,
  rootLabel,
  toolbar,
  detailTitle,
  ssrDetail,
  children
}) {
  const router = useRouter();
  const topicLevels = useMemo(
    () => levels.map((l) => {
      const byId = new Map(l.items.map((it) => [it.id, it]));
      const go = (href, opts) => {
        if (opts?.replace) router.replace(href);
        else router.push(href);
      };
      return {
        id: l.key,
        title: l.title,
        // topicIcon(it.id) gives every row a topic glyph in place of HMDV's neutral fallback ring —
        // on the help levels the item id IS the HelpTopic id, so the same map serves the root and
        // every nested level; a route-driven level brings its own.
        items: l.items.map((it) => ({
          id: it.id,
          label: it.label,
          description: it.description,
          icon: it.icon ?? topicIcon(it.id),
          dividerAfter: it.dividerAfter,
          dividerLabel: it.dividerLabel
        })),
        selectedId: l.selectedId,
        defaultSelectedId: l.defaultSelectedId,
        // Level default for every row — no per-item override needed (each row shares one leadsTo).
        leadsTo: l.leadsTo,
        width: l.width,
        // Every help level is a topic browser, and its unselected frontier is the platform nudge
        // like everywhere else — a card grid repeating the rows the rail is already showing is the
        // second-surface-beside-the-rail that adh/docs/ui/fleet-ui-audit.md §1.5 forbids. `itemNoun` +
        // `overviewHelp` are what make the nudge read for a docs site: without the blurb the shared
        // headline offers to "view or edit" the topic, which is not what this surface does.
        itemNoun: l.itemNoun ?? "topic",
        overviewHelp: l.overviewHelp ?? "Choose a topic from the list to read it here.",
        onSelect: (id, opts) => {
          const href = byId.get(id)?.href;
          if (href) go(href, opts);
        },
        onClear: (opts) => go(l.clearHref, opts),
        clearHref: l.clearHref,
        onPrefetch: (id) => {
          const it = byId.get(id);
          if (!it) return;
          router.prefetch(it.href);
          for (const extra of it.prefetch ?? []) router.prefetch(extra);
        }
      };
    }),
    [levels, router]
  );
  return /* @__PURE__ */ jsx2(
    HierarchicalDetailView,
    {
      levels: topicLevels,
      rootLabel,
      disclosureStyle: "cascading",
      autoHideTopics: true,
      exitGuard: null,
      toolbar,
      detailTitle,
      ssrDetail,
      children
    }
  );
}
export {
  HelpMasterDetail
};
//# sourceMappingURL=HelpMasterDetail.js.map