// src/docs/DocsShell.tsx
import Link from "next/link";

// src/docs/nav.ts
var DOCS_NAV = [
  {
    links: [{ label: "Introduction", slug: "" }]
  },
  {
    label: "Get started",
    links: [
      { label: "Quickstart", slug: "quickstart" },
      { label: "Hub features", slug: "hub-features" }
    ]
  },
  {
    label: "Reference",
    links: [
      { label: "API", slug: "api" },
      { label: "MCP", slug: "mcp" },
      { label: "Errors", slug: "errors" },
      { label: "Webhooks", slug: "webhooks" },
      { label: "Changelog", slug: "changelog" }
    ]
  }
];
function docsHref(basePath, slug) {
  const base = basePath === "/" ? "" : basePath;
  return slug === "" ? base || "/" : `${base}/${slug}`;
}
function docsSlugs() {
  return DOCS_NAV.flatMap((section) => section.links.map((l) => l.slug));
}
function docsNavLabel(slug) {
  for (const section of DOCS_NAV) {
    for (const link of section.links) {
      if (link.slug === slug) return link.label;
    }
  }
  return void 0;
}

// src/docs/DocsShell.tsx
import { jsx, jsxs } from "react/jsx-runtime";
function DocsShell({ basePath, currentSlug, title = "Documentation", nav = DOCS_NAV, children }) {
  const list = /* @__PURE__ */ jsx("ul", { className: "adh-docs__nav-list", children: nav.map((section, i) => /* @__PURE__ */ jsxs("li", { className: "adh-docs__nav-section", children: [
    section.label && /* @__PURE__ */ jsx("p", { className: "adh-docs__nav-heading", children: section.label }),
    /* @__PURE__ */ jsx("ul", { className: "adh-docs__nav-sublist", children: section.links.map((link) => {
      const active = link.slug === currentSlug;
      return /* @__PURE__ */ jsx("li", { children: /* @__PURE__ */ jsx(
        Link,
        {
          href: docsHref(basePath, link.slug),
          className: active ? "adh-docs__nav-link adh-docs__nav-link--active" : "adh-docs__nav-link",
          "aria-current": active ? "page" : void 0,
          children: link.label
        }
      ) }, link.slug || "_index");
    }) })
  ] }, section.label ?? `_${i}`)) });
  return /* @__PURE__ */ jsxs("div", { className: "adh-docs", children: [
    /* @__PURE__ */ jsxs("aside", { className: "adh-docs__sidebar", "aria-label": `${title} navigation`, children: [
      /* @__PURE__ */ jsx("p", { className: "adh-docs__sidebar-title", children: title }),
      list
    ] }),
    /* @__PURE__ */ jsxs("details", { className: "adh-docs__mobile", children: [
      /* @__PURE__ */ jsxs("summary", { className: "adh-docs__mobile-summary", children: [
        title,
        " menu"
      ] }),
      list
    ] }),
    /* @__PURE__ */ jsx("main", { className: "adh-docs__main", children: /* @__PURE__ */ jsx("article", { className: "adh-docs__article", children }) })
  ] });
}

// src/help/content.generated.ts
var HELP_CONTENT_HTML = {
  "mcp-connect": `<h1 id="connect-your-client"><a href="#connect-your-client">Connect your client</a></h1>
<div class="adh-mv-alert adh-mv-alert--note">
<p class="adh-mv-alert-title">Note</p>
<p>Mint an API token first: <code>POST /auth/tokens</code> with your JWT (or via the web
app's API-tokens screen). The raw value is shown <strong>once</strong>.</p>
</div>
<h2 id="claude-desktop"><a href="#claude-desktop">Claude Desktop</a></h2>
<p>Edit <code>~/Library/Application Support/Claude/claude_desktop_config.json</code> (macOS)
or <code>%APPDATA%\\Claude\\claude_desktop_config.json</code> (Windows). Restart Claude
Desktop.</p>
<pre style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;--shiki-light-bg:#fff;--shiki-dark-bg:#24292e"><code><span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">{</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">  "mcpServers"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: {</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">    "agentic-developer-hub"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: {</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">      "type"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF">"streamable-http"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">,</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">      "url"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF">"https://mcp.agenticdeveloperhub.com/mcp"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">,</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">      "headers"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: {</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">        "Authorization"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF">"Bearer &#x3C;paste-token>"</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">      }</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">    }</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">  }</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">}</span></span></code></pre>
<h2 id="claude-code"><a href="#claude-code">Claude Code</a></h2>
<p>From the command line:</p>
<pre style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;--shiki-light-bg:#fff;--shiki-dark-bg:#24292e"><code><span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0">claude</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF"> mcp</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF"> add</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF"> --transport</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF"> http</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF"> agentic-developer-hub</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF"> \\</span></span>
<span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF">  https://mcp.agenticdeveloperhub.com/mcp</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF"> \\</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">  --header</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF"> "Authorization: Bearer &#x3C;paste-token>"</span></span></code></pre>
<h2 id="cursor"><a href="#cursor">Cursor</a></h2>
<p>Edit <code>~/.cursor/mcp.json</code> (or Cursor Settings \u2192 MCP). Restart Cursor.</p>
<pre style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;--shiki-light-bg:#fff;--shiki-dark-bg:#24292e"><code><span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">{</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">  "mcpServers"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: {</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">    "agentic-developer-hub"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: {</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">      "url"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF">"https://mcp.agenticdeveloperhub.com/mcp"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">,</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">      "headers"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: {</span></span>
<span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF">        "Authorization"</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">: </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF">"Bearer &#x3C;paste-token>"</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">      }</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">    }</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">  }</span></span>
<span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8">}</span></span></code></pre>
<h2 id="mcp-inspector"><a href="#mcp-inspector">MCP Inspector</a></h2>
<p>For debugging \u2014 a web UI that lets you call tools by hand:</p>
<pre style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;--shiki-light-bg:#fff;--shiki-dark-bg:#24292e"><code><span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0">npx</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF"> -y</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF"> @modelcontextprotocol/inspector</span></span></code></pre>
<p>Then connect with transport <code>streamable-http</code>, URL
<code>https://mcp.agenticdeveloperhub.com/mcp</code>, and an <code>Authorization: Bearer \u2026</code>
header.</p>`,
  "mcp-details": '<h1 id="details"><a href="#details">Details</a></h1>\n<table>\n<thead>\n<tr>\n<th></th>\n<th></th>\n</tr>\n</thead>\n<tbody>\n<tr>\n<td><strong>Transport</strong></td>\n<td>Streamable HTTP (stateless)</td>\n</tr>\n<tr>\n<td><strong>Endpoint</strong></td>\n<td><code>POST https://mcp.agenticdeveloperhub.com/mcp</code></td>\n</tr>\n<tr>\n<td><strong>Auth</strong></td>\n<td><code>Authorization: Bearer &#x3C;api-token></code></td>\n</tr>\n<tr>\n<td><strong>Session</strong></td>\n<td>Stateless \u2014 each request re-validates the token</td>\n</tr>\n<tr>\n<td><strong>Data scope</strong></td>\n<td>Limited to the user the token belongs to</td>\n</tr>\n</tbody>\n</table>',
  "mcp-overview": `<h1 id="mcp-server"><a href="#mcp-server">MCP Server</a></h1>
<p>A Model Context Protocol endpoint. Your AI agent connects here over Streamable
HTTP and gets a curated set of tools to call against your authenticated data.</p>
<pre style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;--shiki-light-bg:#fff;--shiki-dark-bg:#24292e"><code><span><span>POST https://mcp.agenticdeveloperhub.com/mcp</span></span></code></pre>
<h2 id="what-this-is"><a href="#what-this-is">What this is</a></h2>
<p>MCP is a protocol for AI agents to discover and call tools on a server. It's a
sibling of the REST API, not a replacement.</p>
<h3 id="mcp--this-server"><a href="#mcp--this-server">MCP \u2014 this server</a></h3>
<ul>
<li>For LLM agents, not browsers</li>
<li>Single endpoint (<code>POST /mcp</code>)</li>
<li>JSON-RPC over HTTP</li>
<li>Tool discovery built in (<code>tools/list</code>)</li>
<li>Auth: <code>Authorization: Bearer &#x3C;api-token></code></li>
</ul>
<h3 id="rest-api"><a href="#rest-api">REST API</a></h3>
<ul>
<li>For humans and traditional clients</li>
<li>Resource-oriented (<code>/\u2026</code>)</li>
<li>OpenAPI 3.1 spec \u2014 see the <a href="/rest-api">API reference</a></li>
<li>Auth: JWT (email/password or OAuth)</li>
</ul>`,
  "mcp-tools": `<h1 id="tool-surface"><a href="#tool-surface">Tool surface</a></h1>
<p>54 tools, scoped to the user behind the API token. Revoke a token
to cut access immediately. Profile tools return only rows the acting agent has
been granted read access to via the data bucket ACL.</p>
<h2 id="persona-storage--19-tools"><a href="#persona-storage--19-tools">Persona Storage \xB7 19 tools</a></h2>
<p>Key/value, lists, counters, memory, events, queues, and keyword tags \u2014 agent-managed structured state.</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>dataKvGet</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>dataKvSet</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataKvDelete</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataCounterGet</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>dataCounterIncr</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataListGet</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>dataListAppend</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataListRemove</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataMemoryGet</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>dataMemorySet</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataEventAppend</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataEventQuery</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>dataQueueEnqueue</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataQueueDequeue</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataQueueAck</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataQueueNack</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataKeywordTag</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataKeywordUntag</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>dataKeywordSearch</code></td>
<td>Read</td>
</tr>
</tbody>
</table>
<h2 id="discussions--4-tools"><a href="#discussions--4-tools">Discussions \xB7 4 tools</a></h2>
<p>Search and browse the community forum.</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>searchThreads</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>listCategories</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyBookmarks</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getRecentNotifications</code></td>
<td>Read</td>
</tr>
</tbody>
</table>
<h2 id="profile--12-tools"><a href="#profile--12-tools">Profile \xB7 12 tools</a></h2>
<p>Your structured profile \u2014 jobs, education, locations, contacts, relationships, dates, tags, notes \u2014 plus categories and keyword lookups. Returns only rows the acting agent has been granted read access to via the data bucket ACL.</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>getMyProfile</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyJobs</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyEducation</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyLocations</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyContacts</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyRelationships</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyTags</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getMyDates</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>searchMyNotes</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>searchMyData</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getCategoryContents</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>getKeywordsFor</code></td>
<td>Read</td>
</tr>
</tbody>
</table>
<h2 id="personas--2-tools"><a href="#personas--2-tools">Personas \xB7 2 tools</a></h2>
<p>Discover personas visible to you.</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>personasPersonaList</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>personasPersonaGet</code></td>
<td>Read</td>
</tr>
</tbody>
</table>
<h2 id="teams--3-tools"><a href="#teams--3-tools">Teams \xB7 3 tools</a></h2>
<p>Administer the rosters of teams you manage \u2014 for an organization persona, the org-owned teams (list, add by email, remove).</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>teamMemberList</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>teamMemberAdd</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>teamMemberRemove</code></td>
<td>Write</td>
</tr>
</tbody>
</table>
<h2 id="monitored-sites--7-tools"><a href="#monitored-sites--7-tools">Monitored Sites \xB7 7 tools</a></h2>
<p>Manage uptime monitors for your sites and HTTP endpoints.</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>monitoredSiteList</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>monitoredSiteAdd</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>monitoredSiteRemove</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>monitoredEndpointList</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>monitoredEndpointAdd</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>monitoredEndpointRemove</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>monitoredEndpointStatus</code></td>
<td>Read</td>
</tr>
</tbody>
</table>
<h2 id="projects--6-tools"><a href="#projects--6-tools">Projects \xB7 6 tools</a></h2>
<p>List projects, their iterations and their work items, update a work item \u2014 including committing it to an iteration and sizing it \u2014 and post a comment: the agent write surface for the Projects feature (acts as the token subject).</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>projectListProjects</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>projectListIterations</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>projectListWorkItems</code></td>
<td>Read</td>
</tr>
<tr>
<td><code>projectUpdateWorkItem</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>projectAddComment</code></td>
<td>Write</td>
</tr>
<tr>
<td><code>projectListComments</code></td>
<td>Read</td>
</tr>
</tbody>
</table>
<h2 id="persona-knowledge--1-tools"><a href="#persona-knowledge--1-tools">Persona Knowledge \xB7 1 tools</a></h2>
<p>Full-text search over the acting persona's OWN knowledge corpus \u2014 the markdown rows referenced by a row-mode bucket type it has been granted read access to. Returns keyword-centred excerpts, never whole documents.</p>
<table>
<thead>
<tr>
<th>Tool</th>
<th>Access</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>searchPersonaKnowledge</code></td>
<td>Read</td>
</tr>
</tbody>
</table>`,
  "overview": '<h1 id="overview"><a href="#overview">Overview</a></h1>\n<p>This is the help section for the Agentic Developer Hub.</p>\n<p><strong>Hub Features</strong> covers the hub itself: workspaces, personas, documents, projects, files, products and the people you work with. Each feature has a page on what it is, a page for each of its parts, a card on what an application can do with it, and a card on why it is built the way it is.</p>\n<p><strong>REST API</strong> lists every endpoint the hub serves, with its parameters, request and responses. You can try a call against your current session.</p>\n<p><strong>MCP</strong> explains how an AI agent uses the Model Context Protocol with the hub: what the server is, how to connect your client, and the tools it offers.</p>\n<p>Select a topic from the list to begin.</p>'
};

// src/docs/content.ts
function docContentKey(slug) {
  return slug === "" ? "index" : slug.replaceAll("/", "-");
}
function getDocHtml(slug) {
  return HELP_CONTENT_HTML[docContentKey(slug)];
}
function getDocHtmlByKey(key) {
  return HELP_CONTENT_HTML[key];
}

// src/docs/MarkdownHtml.tsx
import { jsx as jsx2 } from "react/jsx-runtime";
function MarkdownHtml({ html, className }) {
  return /* @__PURE__ */ jsx2(
    "div",
    {
      className: className ? `adh-mv-prose ${className}` : "adh-mv-prose",
      dangerouslySetInnerHTML: { __html: html }
    }
  );
}
export {
  DOCS_NAV,
  DocsShell,
  MarkdownHtml,
  docContentKey,
  docsHref,
  docsNavLabel,
  docsSlugs,
  getDocHtml,
  getDocHtmlByKey
};
//# sourceMappingURL=index.js.map