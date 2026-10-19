'use client'

"use client";

// src/help/HelpProvider.tsx
import dynamic from "next/dynamic";
import { createContext, useCallback, useContext, useMemo, useState } from "react";

// src/help/topics.ts
var HELP_TOPICS = [
  {
    id: "overview",
    label: "Overview",
    slug: "overview",
    description: "What this site holds, and where to start.",
    contentKey: "overview"
  },
  {
    id: "rest-api",
    label: "REST API",
    slug: "rest-api",
    description: "Browse every REST endpoint and try calls against your session.",
    view: "api"
  },
  {
    // A section, not a monolithic page: the old single mcp.md split into per-concern child topics.
    // It does NOT land on the children's select nudge: /mcp is the published address of the MCP
    // docs (the MCP host's root redirects a browser here, as does the `/docs/mcp` redirect), so
    // arriving there must read as documentation, not as a menu. The `landingChildId` auto-selects
    // Overview — the reader lands on prose with the siblings beside it.
    id: "mcp",
    label: "MCP",
    slug: "mcp",
    description: "Connect an agent to the hub over the Model Context Protocol.",
    landingChildId: "mcp-overview",
    children: [
      { id: "mcp-overview", label: "Overview", slug: "mcp/overview", description: "What the MCP server is, and how it relates to the REST API.", contentKey: "mcp-overview" },
      { id: "mcp-connect", label: "Connect a client", slug: "mcp/connect", description: "Point Claude Desktop, Claude Code, Cursor, or the Inspector at the server.", contentKey: "mcp-connect" },
      { id: "mcp-tools", label: "Tools", slug: "mcp/tools", description: "Every tool the server exposes, grouped by area.", contentKey: "mcp-tools" },
      { id: "mcp-details", label: "Details", slug: "mcp/details", description: "Transport, auth, session, and data-scope facts.", contentKey: "mcp-details" }
    ]
  },
  {
    // The Hub Features document is not markdown in this package: the help site builds it with
    // content-buildr from `content/hub-features/` in adhubwebsite and serves it under `/hub` with
    // its own cascading lists, one per level of the document. So this is a leaf with a `view`, like
    // the REST API: on the site the `/hub` route owns it, and the modal links out to it.
    id: "hub",
    label: "Hub Features",
    slug: "hub",
    description: "Every feature of the Agentic Developer Hub, described one at a time.",
    view: "hub"
  }
];
function isLeaf(topic) {
  return !topic.children || topic.children.length === 0;
}
function findTopicPath(id, topics = HELP_TOPICS) {
  for (const topic of topics) {
    if (topic.id === id) return [topic];
    if (topic.children) {
      const deeper = findTopicPath(id, topic.children);
      if (deeper) return [topic, ...deeper];
    }
  }
  return null;
}

// src/help/HelpProvider.tsx
import { jsx, jsxs } from "react/jsx-runtime";
var HelpWindow = dynamic(
  () => import("@agentic-toolkit/adh/help/HelpWindow").then((m) => m.HelpWindow)
);
var HelpContext = createContext(null);
function HelpProvider({ children }) {
  const [isOpen, setIsOpen] = useState(false);
  const [path, setPath] = useState([]);
  const open = useCallback((topicId) => {
    if (topicId) {
      const nodes = findTopicPath(topicId);
      setPath(nodes ? nodes.map((n) => n.id) : []);
    }
    setIsOpen(true);
  }, []);
  const close = useCallback(() => setIsOpen(false), []);
  const value = useMemo(() => ({ isOpen, open, close }), [isOpen, open, close]);
  return /* @__PURE__ */ jsxs(HelpContext.Provider, { value, children: [
    children,
    isOpen && /* @__PURE__ */ jsx(HelpWindow, { open: true, onClose: close, path, onPathChange: setPath })
  ] });
}
function useHelp() {
  return useContext(HelpContext) ?? NOOP;
}
var NOOP = { isOpen: false, open: () => {
}, close: () => {
} };

// src/help/index.ts
import { HelpWindow as HelpWindow2 } from "@agentic-toolkit/adh/help/HelpWindow";
export {
  HELP_TOPICS,
  HelpProvider,
  HelpWindow2 as HelpWindow,
  findTopicPath,
  isLeaf,
  useHelp
};
//# sourceMappingURL=index.js.map