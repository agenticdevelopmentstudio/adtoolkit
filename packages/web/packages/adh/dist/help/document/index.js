// src/help/document/parts.ts
var TUTORIAL_PARTS = [
  { id: "definitions", label: "Definitions" },
  { id: "steps", label: "Steps" }
];
var HEADING = /^\s*<h3(?:\s[^>]*)?>([\s\S]*?)<\/h3>\s*$/;
var ENTITIES = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
  mdash: "\u2014",
  ndash: "\u2013",
  hellip: "\u2026",
  lsquo: "\u2018",
  rsquo: "\u2019",
  ldquo: "\u201C",
  rdquo: "\u201D",
  laquo: "\xAB",
  raquo: "\xBB",
  middot: "\xB7",
  bull: "\u2022",
  times: "\xD7",
  larr: "\u2190",
  rarr: "\u2192",
  copy: "\xA9",
  reg: "\xAE",
  trade: "\u2122"
};
function decodeEntity(entity, body) {
  if (body[0] === "#") {
    const code = body[1] === "x" || body[1] === "X" ? parseInt(body.slice(2), 16) : parseInt(body.slice(1), 10);
    return Number.isInteger(code) && code > 0 && code <= 1114111 ? String.fromCodePoint(code) : entity;
  }
  return ENTITIES[body] ?? entity;
}
function plainText(html) {
  return html.replace(/<[^>]*>/g, "").replace(/&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);/g, decodeEntity).replace(/\s+/g, " ").trim();
}
function slugOf(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}
function sectionsOf(blocks) {
  const lead = [];
  const sections = [];
  const used = /* @__PURE__ */ new Set();
  for (const block of blocks) {
    const heading = HEADING.exec(block);
    if (heading) {
      const titleHtml = (heading[1] ?? "").trim();
      const title = plainText(titleHtml);
      const base = slugOf(title) || "section";
      let id = base;
      for (let n = 2; used.has(id); n++) id = `${base}-${n}`;
      used.add(id);
      sections.push({ id, title, titleHtml, html: [] });
    } else if (sections.length) {
      sections.at(-1).html.push(block);
    } else {
      lead.push(block);
    }
  }
  return { lead, sections };
}
var ORDERED = /^\s*<ol(?:\s[^>]*)?>([\s\S]*)<\/ol>\s*$/;
function listStart(block) {
  const start = /^\s*<ol\s[^>]*\bstart="?(\d+)/.exec(block);
  return start ? Number(start[1]) : 1;
}
function listItems(inner) {
  const items = [];
  const tag = /<(\/?)li(?:\s[^>]*)?>/g;
  let depth = 0;
  let start = -1;
  for (const match of inner.matchAll(tag)) {
    const at = match.index ?? 0;
    if (!match[1]) {
      if (depth === 0) start = at + match[0].length;
      depth++;
    } else if (depth > 0) {
      depth--;
      if (depth === 0 && start >= 0) {
        items.push(inner.slice(start, at).trim());
        start = -1;
      }
    }
  }
  return items;
}
var SUBSTEP_ID_WORDS = 6;
function substepsOf(stepId, items) {
  const used = /* @__PURE__ */ new Set();
  return items.map((html) => {
    const own = html.split(/<(?:ol|ul|pre|blockquote|div|table)[\s>]/)[0] ?? "";
    const words = slugOf(plainText(own)).split("-").filter(Boolean).slice(0, SUBSTEP_ID_WORDS);
    const base = words.join("-") || "item";
    let slug = base;
    for (let n = 2; used.has(slug); n++) slug = `${base}-${n}`;
    used.add(slug);
    return { id: `${stepId}/${slug}`, html };
  });
}
function stepOf(section) {
  const { html: blocks } = section;
  for (let k = 0; k < blocks.length; k++) {
    const block = blocks[k] ?? "";
    const list = ORDERED.exec(block);
    if (!list) continue;
    const start = listStart(block);
    const items = listItems(list[1] ?? "");
    let end = k + 1;
    for (let j = k + 1; j < blocks.length; j++) {
      const next = ORDERED.exec(blocks[j] ?? "");
      if (!next) continue;
      if (!items.length || listStart(blocks[j] ?? "") !== start + items.length) break;
      items[items.length - 1] += blocks.slice(end, j).join("");
      items.push(...listItems(next[1] ?? ""));
      end = j + 1;
    }
    if (items.length < 2) continue;
    return {
      ...section,
      before: blocks.slice(0, k),
      substeps: substepsOf(section.id, items),
      start,
      after: blocks.slice(end)
    };
  }
  return { ...section, before: blocks, substeps: [], start: 1, after: [] };
}
function tutorialLinks(html, base, known) {
  const out = [];
  const escaped = base.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const href = new RegExp(`href="${escaped}/([^"/#?]+)`, "g");
  for (const match of html.matchAll(href)) {
    const id = match[1];
    if (id && known.has(id) && !out.includes(id)) out.push(id);
  }
  return out;
}
function isTutorialsLine(block) {
  return /^\s*<p[\s>]/.test(block) && plainText(block).startsWith("Tutorials:");
}
function glossaryOf(description, base, tutorialIds) {
  const { sections } = sectionsOf(description);
  return sections.map((section) => {
    const line = [...section.html].reverse().find(isTutorialsLine);
    const html = section.html.filter((block) => block !== line);
    return {
      ...section,
      html,
      text: plainText(html.join(" ")),
      tutorials: line ? tutorialLinks(line, base, tutorialIds) : []
    };
  });
}
function termsFor(terms, tutorialId) {
  return terms.filter((term) => term.tutorials.includes(tutorialId));
}
function termMatches(term, query) {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return true;
  const haystack = `${term.title} ${term.text}`.toLowerCase();
  return words.every((word) => haystack.includes(word));
}
var METHODS = /* @__PURE__ */ new Set(["GET", "POST", "PUT", "PATCH", "DELETE"]);
function apiRoutesOf(blocks) {
  const out = [];
  const seen = /* @__PURE__ */ new Set();
  const add = (methods, text) => {
    const path = text.split(/[?#]/)[0] ?? text;
    for (const method of methods) {
      const key = `${method ?? "*"} ${path}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(method ? { method, path } : { path });
    }
  };
  for (const block of blocks) {
    let pending = [];
    let last = null;
    for (const match of block.matchAll(/<code>([\s\S]*?)<\/code>/g)) {
      const text = plainText(match[1] ?? "");
      const upper = text.toUpperCase();
      if (METHODS.has(upper)) {
        const after = block.slice((match.index ?? 0) + match[0].length);
        if (last && /^\s*(?:to|of|on|from)\s+it\b/i.test(plainText(after.split("<code>")[0] ?? ""))) {
          add([upper], last);
          continue;
        }
        pending.push(upper);
        continue;
      }
      const both = /^([A-Za-z]+)\s+(\/\S*)$/.exec(text);
      if (both && METHODS.has(both[1].toUpperCase())) {
        add([both[1].toUpperCase()], both[2]);
        last = both[2].split(/[?#]/)[0] ?? both[2];
        pending = [];
        continue;
      }
      if (!text.startsWith("/")) continue;
      add(pending.length ? pending : [void 0], text);
      last = text.split(/[?#]/)[0] ?? text;
      pending = [];
    }
  }
  return out;
}

// src/help/document/model.ts
var OVERVIEW_ID = "~overview";
var OVERVIEW_LABEL = "Overview";
var ROOT_KEY = "";
function hasOverview(node) {
  return node.told && node.children.length > 0;
}
function cardOf(bodies, id, title) {
  const card = bodies[id];
  if (!card) throw new Error(`the ${title} document lists "${id}" as a page but holds no card for it.`);
  return card;
}
function withTutorialParts(tree, bodies, base, glossaryId, title) {
  const glossary = tree.find((node) => node.id === glossaryId);
  if (!glossary || !glossary.told) {
    throw new Error(
      `the ${title} document has no "${glossaryId}" root page to be its Glossary \u2014 add it to the root's children.`
    );
  }
  const tutorialIds = new Set(
    tree.filter((node) => node.id !== glossaryId && node.told && !node.children.length).map((n) => n.id)
  );
  const terms = glossaryOf(cardOf(bodies, glossaryId, title).description, base, tutorialIds);
  const out = tree.map((node) => {
    if (!tutorialIds.has(node.id)) return node;
    const card = cardOf(bodies, node.id, title);
    const has = {
      definitions: termsFor(terms, node.id).length > 0,
      steps: sectionsOf(card.description).sections.length > 0
    };
    if (!has.definitions && !has.steps) {
      throw new Error(
        `the ${title} tutorial "${node.id}" has no ### step and no ${glossaryId} term linking to it \u2014 give it steps.`
      );
    }
    const children = TUTORIAL_PARTS.filter((part) => has[part.id]).map(
      (part) => ({
        id: part.id,
        label: part.label,
        addr: node.addr,
        told: true,
        open: [...node.open, part.id],
        children: [],
        part: part.id,
        owner: node.id
      })
    );
    return { ...node, children };
  });
  return { tree: out, index: { glossaryId, terms, tutorialIds } };
}
function contentDocument(source) {
  const { topicId, base, title, descriptionTitle } = source;
  const built = source.index;
  const bodies = source.bodies;
  if (built.length === 0) {
    throw new Error(
      `the ${title} document holds no entries: it was not built (${source.builtFrom} \u2192 content-buildr).`
    );
  }
  const { tree, index: tutorials } = source.tutorials ? withTutorialParts(built, bodies, base, source.tutorials.glossaryId, title) : { tree: built, index: null };
  const rootTold = () => bodies[ROOT_KEY] != null;
  const href = (segments) => [base, ...segments].join("/");
  function kindOf(node) {
    if (node.part) return node.part;
    if (!tutorials) return void 0;
    if (node.id === tutorials.glossaryId) return "glossary";
    if (tutorials.tutorialIds.has(node.id)) return "tutorial";
    return void 0;
  }
  function paths() {
    const out = [];
    if (rootTold()) out.push([OVERVIEW_ID]);
    const walk = (nodes, here) => {
      for (const node of nodes) {
        const path = [...here, node.id];
        out.push(path);
        if (hasOverview(node)) out.push([...path, OVERVIEW_ID]);
        walk(node.children, path);
      }
    };
    walk(tree, []);
    return out;
  }
  function canonicalPaths() {
    return [[], ...paths()].filter((path) => {
      const resolved = view(path);
      return resolved != null && resolved.canonical.join("/") === path.join("/");
    });
  }
  function railOf(id, railTitle, owner, above, selectedId) {
    const nodes = owner ? owner.children : tree;
    const told = owner ? owner.told : rootTold();
    const items = told ? [
      {
        id: OVERVIEW_ID,
        label: OVERVIEW_LABEL,
        open: [...above, OVERVIEW_ID],
        opens: false,
        overview: false
      }
    ] : [];
    let heading;
    for (const node of nodes) {
      const last = items.at(-1);
      if (node.listHeading && node.listHeading !== heading && last) last.section = node.listHeading;
      heading = node.listHeading;
      items.push({
        id: node.id,
        label: node.label,
        open: node.open,
        opens: node.children.length > 0,
        overview: hasOverview(node),
        kind: kindOf(node)
      });
    }
    const glossaryRow = items.findIndex((item) => item.kind === "glossary");
    const belowGlossary = items[glossaryRow + 1];
    if (glossaryRow >= 0 && belowGlossary && !items[glossaryRow].section) {
      items[glossaryRow].divider = true;
    }
    return { id, title: railTitle, items, selectedId, above, overview: told };
  }
  function tutorialView(node, part) {
    if (!tutorials || !tutorials.tutorialIds.has(node.id)) return null;
    const card = cardOf(bodies, node.id, title);
    const { lead, sections } = sectionsOf(card.description);
    return {
      id: node.id,
      part,
      lead,
      steps: sections.map(stepOf),
      terms: termsFor(tutorials.terms, node.id),
      glossary: { name: cardOf(bodies, tutorials.glossaryId, title).name, href: href([tutorials.glossaryId]) },
      api: apiRoutesOf(card.api)
    };
  }
  function glossaryView() {
    if (!tutorials) return null;
    const named = {};
    for (const node of tree) {
      if (tutorials.tutorialIds.has(node.id)) named[node.id] = { name: node.label, href: href(node.open) };
    }
    return { terms: tutorials.terms, tutorials: named };
  }
  function view(asked) {
    const overview = asked.at(-1) === OVERVIEW_ID;
    const path = overview ? asked.slice(0, -1) : asked;
    const trail = [];
    let nodes = tree;
    for (const id of path) {
      const node = nodes.find((n) => n.id === id);
      if (!node) return null;
      trail.push(node);
      nodes = node.children;
    }
    const rails = [
      railOf(
        "level-0",
        title,
        null,
        [],
        trail[0]?.id ?? (overview && path.length === 0 ? OVERVIEW_ID : null)
      )
    ];
    trail.forEach((node, depth) => {
      if (!node.children.length) return;
      const below = trail[depth + 1]?.id ?? (overview && depth === trail.length - 1 ? OVERVIEW_ID : null);
      rails.push(railOf(`level-${depth + 1}`, node.label, node, path.slice(0, depth + 1), below));
    });
    const entry = trail.at(-1) ?? null;
    if (overview) {
      const owner = entry ? hasOverview(entry) : rootTold();
      if (!owner) return null;
    }
    const reads = entry ? overview || !entry.children.length ? entry.owner ?? entry.id : null : overview ? ROOT_KEY : null;
    const told = entry ? entry.told : rootTold();
    const card = reads == null || !told ? null : cardOf(bodies, reads, title);
    const canonical = reads != null || !rails.at(-1).overview ? asked : [...asked, OVERVIEW_ID];
    let tutorial = null;
    if (entry?.part) tutorial = tutorialView(trail.at(-2), entry.part);
    else if (entry && overview) tutorial = tutorialView(entry, "overview");
    const glossary = tutorials && entry?.id === tutorials.glossaryId && trail.length === 1 ? glossaryView() : null;
    const name = card?.name ?? entry?.label ?? title;
    const pageTitle = entry?.part ? `${entry.label}: ${name}` : name;
    return { rails, entry, card, title: pageTitle, canonical, tutorial, glossary };
  }
  return { topicId, base, title, descriptionTitle, paths, canonicalPaths, view, href };
}

// src/help/document/progress.ts
function progressKey(tutorialId) {
  return `adh-help:tutorial-progress:${tutorialId}`;
}
function startOf(steps) {
  return { v: 1, done: [], active: steps[0]?.id ?? null };
}
function readProgress(raw, steps) {
  if (!raw) return startOf(steps);
  try {
    const saved = JSON.parse(raw);
    if (saved?.v !== 1 || !Array.isArray(saved.done)) return startOf(steps);
    const ids = new Set(steps.flatMap((s) => [s.id, ...(s.substeps ?? []).map((sub) => sub.id)]));
    const kept = saved.done.filter((id) => typeof id === "string" && ids.has(id));
    const done = settle(steps, kept);
    const active = typeof saved.active === "string" && steps.some((s) => s.id === saved.active) ? saved.active : nextOpen(steps, done, -1);
    return { v: 1, done, active };
  } catch {
    return startOf(steps);
  }
}
function nextOpen(steps, done, from) {
  for (let k = 1; k <= steps.length; k++) {
    const step = steps[(from + k) % steps.length];
    if (step && !done.includes(step.id)) return step.id;
  }
  return null;
}
function subIds(step) {
  return (step.substeps ?? []).map((sub) => sub.id);
}
function settle(steps, done) {
  const out = [...new Set(done)];
  for (const step of steps) {
    const subs = subIds(step);
    if (!subs.length) continue;
    if (out.includes(step.id)) {
      for (const sub of subs) if (!out.includes(sub)) out.push(sub);
    } else if (subs.every((sub) => out.includes(sub))) {
      out.push(step.id);
    }
  }
  return out;
}
function toggle(progress, steps, id, checked) {
  const at = steps.findIndex((s) => s.id === id || subIds(s).includes(id));
  const step = steps[at];
  if (!step) return progress;
  const subs = subIds(step);
  const touched = id === step.id ? [step.id, ...subs] : checked ? [id] : [id, step.id];
  if (!checked) {
    return { v: 1, done: progress.done.filter((d) => !touched.includes(d)), active: step.id };
  }
  const done = settle(steps, [...progress.done, ...touched]);
  return { v: 1, done, active: done.includes(step.id) ? nextOpen(steps, done, at) : step.id };
}

// src/help/document/DocumentSurface.tsx
import {
  Book as Book2,
  FileText,
  Folder,
  GraduationCap,
  Info,
  LayoutGrid,
  ListChecks as ListChecks2,
  Quote as Quote2
} from "lucide-react";
import {
  HelpMasterDetail
} from "@adh-sdk/adh/help/HelpMasterDetail";

// src/help/document/DocumentDetail.tsx
import Link2 from "next/link";
import {
  Activity,
  Book,
  BookOpenText,
  Braces,
  Cloud,
  Code2,
  Cpu,
  Database,
  Globe,
  Image as ImageIcon,
  Layers,
  Link2 as Link22,
  ListChecks,
  MonitorSmartphone,
  Plug,
  Quote,
  Wrench
} from "lucide-react";
import { StatCard } from "@adh-sdk/ui/blocks";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Favicon } from "@adh-sdk/ui/components/favicon";
import { TONE_TEXT_CLASS } from "@adh-sdk/ui/lib/tone";
import { ApiButton } from "@adh-sdk/api-explorer";
import { GlossarySearch } from "@adh-sdk/adh/help/document/GlossarySearch";
import { TutorialSteps } from "@adh-sdk/adh/help/document/TutorialSteps";

// src/help/document/TermBlock.tsx
import Link from "next/link";
import { jsx, jsxs } from "react/jsx-runtime";
function TermBlock({
  term,
  href,
  anchor = false,
  arrived = false,
  children
}) {
  const name = /* @__PURE__ */ jsx("span", { dangerouslySetInnerHTML: { __html: term.titleHtml } });
  return /* @__PURE__ */ jsxs(
    "div",
    {
      id: anchor ? term.id : void 0,
      "data-arrived": arrived || void 0,
      className: "doc-term scroll-mt-6 flex flex-col gap-2 rounded-md border border-apt-border bg-apt-surface px-4 py-3.5",
      children: [
        /* @__PURE__ */ jsx("dt", { className: "text-[1.1rem] font-[650] leading-snug text-apt-gold", children: href ? /* @__PURE__ */ jsx(Link, { href, className: "underline-offset-4 hover:underline", children: name }) : name }),
        /* @__PURE__ */ jsxs("dd", { className: "flex flex-col gap-2", children: [
          term.html.map((html, i) => /* @__PURE__ */ jsx("div", { className: "doc-copy", dangerouslySetInnerHTML: { __html: html } }, i)),
          children
        ] })
      ]
    }
  );
}

// src/help/document/DocumentDetail.tsx
import { Fragment, jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function GithubMark() {
  return /* @__PURE__ */ jsx2("svg", { width: "18", height: "18", viewBox: "0 0 24 24", fill: "currentColor", "aria-hidden": "true", children: /* @__PURE__ */ jsx2("path", { d: "M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" }) });
}
var TECH = {
  languages: { title: "Languages", icon: Code2, hue: "blue" },
  frameworks: { title: "Frameworks", icon: Layers, hue: "accent" },
  data: { title: "Data", icon: Database, hue: "success" },
  hosting: { title: "Hosting", icon: Cloud, hue: "orange" },
  services: { title: "Services", icon: Activity, hue: "error" },
  protocols: { title: "APIs & protocols", icon: Plug, hue: "blue" },
  platforms: { title: "Runs on", icon: MonitorSmartphone, hue: "success" },
  tooling: { title: "Tooling", icon: Wrench, hue: "orange" }
};
function glyph(Icon, hue) {
  return /* @__PURE__ */ jsx2(Icon, { className: `size-4 ${TONE_TEXT_CLASS[hue]}`, strokeWidth: 2.2 });
}
function Panel({
  title,
  icon,
  hue,
  footnote,
  children
}) {
  return /* @__PURE__ */ jsx2(StatCard, { title, icon: glyph(icon, hue), footnote, className: "bg-apt-surface-2", children: /* @__PURE__ */ jsx2("div", { className: "flex flex-col gap-3", children }) });
}
function Caption({ icon: Icon, hue, children }) {
  return /* @__PURE__ */ jsxs2("span", { className: "inline-flex items-center gap-1.5 font-mono text-[11px] font-semibold uppercase tracking-[0.06em] text-apt-text", children: [
    /* @__PURE__ */ jsx2(Icon, { className: `size-3.5 shrink-0 ${TONE_TEXT_CLASS[hue]}`, strokeWidth: 2.2 }),
    children
  ] });
}
function Copy({ html, className = "" }) {
  return /* @__PURE__ */ jsx2("div", { className: `doc-copy ${className}`, dangerouslySetInnerHTML: { __html: html } });
}
function Source({ lead, from }) {
  return /* @__PURE__ */ jsxs2("span", { children: [
    lead,
    " ",
    /* @__PURE__ */ jsx2(Link2, { href: from.href, className: "text-apt-gold underline-offset-2 hover:underline", children: from.name })
  ] });
}
function isInternal(url) {
  return url.startsWith("/") && !url.startsWith("//");
}
function LinkIcon({ link }) {
  if (link.url && isInternal(link.url)) {
    return /* @__PURE__ */ jsx2(BookOpenText, { className: "size-4 text-apt-gold", strokeWidth: 2.2 });
  }
  if (link.kind === "github") {
    return /* @__PURE__ */ jsx2("span", { className: "inline-flex size-4 items-center justify-center text-apt-text [&_svg]:size-4", children: /* @__PURE__ */ jsx2(GithubMark, {}) });
  }
  return /* @__PURE__ */ jsx2(
    Favicon,
    {
      href: link.url ?? "",
      size: 16,
      fallback: /* @__PURE__ */ jsx2(Globe, { className: "size-4 text-apt-blue", strokeWidth: 2.2 })
    }
  );
}
function LinkRow({ link }) {
  if (!link.url) {
    return /* @__PURE__ */ jsx2("li", { children: /* @__PURE__ */ jsx2(Copy, { html: link.note ?? link.name, className: "text-sm" }) });
  }
  const note = link.note ? /* @__PURE__ */ jsx2("span", { className: "block text-xs text-apt-text-dim", dangerouslySetInnerHTML: { __html: link.note } }) : null;
  if (isInternal(link.url)) {
    return /* @__PURE__ */ jsxs2("li", { className: "flex items-start gap-2.5", children: [
      /* @__PURE__ */ jsx2("span", { className: "mt-[3px] inline-flex", children: /* @__PURE__ */ jsx2(LinkIcon, { link }) }),
      /* @__PURE__ */ jsxs2("span", { className: "min-w-0 text-sm leading-6", children: [
        /* @__PURE__ */ jsx2(
          Link2,
          {
            href: link.url,
            className: "font-semibold text-apt-gold underline-offset-2 hover:underline",
            "data-testid": "doc-internal-link",
            children: link.name
          }
        ),
        note
      ] })
    ] });
  }
  return /* @__PURE__ */ jsxs2("li", { className: "flex items-start gap-2.5", children: [
    /* @__PURE__ */ jsx2("span", { className: "mt-[3px] inline-flex", children: /* @__PURE__ */ jsx2(LinkIcon, { link }) }),
    /* @__PURE__ */ jsxs2("span", { className: "min-w-0 text-sm leading-6", children: [
      /* @__PURE__ */ jsxs2("span", { className: "font-semibold text-apt-text", children: [
        link.name,
        ":"
      ] }),
      " ",
      /* @__PURE__ */ jsx2(
        "a",
        {
          href: link.url,
          target: "_blank",
          rel: "noopener noreferrer",
          className: "break-all font-mono text-[13px] text-apt-gold underline-offset-2 hover:underline",
          children: link.url
        }
      ),
      note
    ] })
  ] });
}
function TechDetail({ tech }) {
  return /* @__PURE__ */ jsxs2(
    Panel,
    {
      title: "Tech Detail",
      icon: Cpu,
      hue: "accent",
      footnote: tech.from ? /* @__PURE__ */ jsx2(Source, { lead: "The stack of", from: tech.from }) : void 0,
      children: [
        tech.stack.length ? /* @__PURE__ */ jsx2("dl", { className: "grid grid-cols-[minmax(8.5rem,auto)_1fr] items-start gap-x-4 gap-y-2.5", children: tech.stack.map(({ kind, terms }) => {
          const meta = TECH[kind];
          if (!meta) {
            throw new Error(
              `DocumentDetail has no caption, glyph or tint for tech kind "${kind}" (added to content/adhubwebsite/hub-features/tech.json in adhcontent?) \u2014 add it to TECH.`
            );
          }
          return /* @__PURE__ */ jsxs2("div", { className: "contents", children: [
            /* @__PURE__ */ jsx2("dt", { className: "pt-[3px]", children: /* @__PURE__ */ jsx2(Caption, { icon: meta.icon, hue: meta.hue, children: meta.title }) }),
            /* @__PURE__ */ jsx2("dd", { className: "flex flex-wrap gap-1.5", children: terms.map(
              (t) => t.url ? /* @__PURE__ */ jsx2(
                "a",
                {
                  href: t.url,
                  target: "_blank",
                  rel: "noopener noreferrer",
                  className: "rounded-sm transition-opacity hover:opacity-80",
                  children: /* @__PURE__ */ jsx2(Badge, { variant: meta.hue, children: t.name })
                },
                t.name
              ) : /* @__PURE__ */ jsx2(Badge, { variant: meta.hue, children: t.name }, t.name)
            ) })
          ] }, kind);
        }) }) : null,
        tech.notes.length ? /* @__PURE__ */ jsx2("div", { className: `flex flex-col gap-2 ${tech.stack.length ? "border-t border-apt-border pt-3" : ""}`, children: tech.notes.map((html, i) => /* @__PURE__ */ jsx2(Copy, { html }, i)) }) : null
      ]
    }
  );
}
function Blocks({ html }) {
  return /* @__PURE__ */ jsx2(Fragment, { children: html.map((block, i) => /* @__PURE__ */ jsx2(Copy, { html: block }, i)) });
}
function Header({ card, kicker, action }) {
  const heading = /* @__PURE__ */ jsx2("h1", { className: "text-[1.9rem] font-[650] leading-tight text-apt-text", children: card.name });
  return /* @__PURE__ */ jsxs2("header", { className: "flex flex-col gap-2 border-b border-apt-border pb-5", children: [
    kicker ? /* @__PURE__ */ jsx2("span", { className: "w-fit font-mono text-[11px] font-semibold uppercase tracking-[0.13em] text-apt-text-muted", children: kicker }) : card.crumb ? /* @__PURE__ */ jsx2(
      Link2,
      {
        href: card.crumb.href,
        className: "w-fit font-mono text-[11px] font-semibold uppercase tracking-[0.13em] text-apt-text-muted hover:text-apt-gold",
        children: card.crumb.name
      }
    ) : null,
    action ? /* @__PURE__ */ jsxs2("div", { className: "flex flex-wrap items-start justify-between gap-3", children: [
      heading,
      /* @__PURE__ */ jsx2("div", { className: "shrink-0 pt-1.5", children: action })
    ] }) : heading
  ] });
}
function Blurb({ card }) {
  if (!card.blurb && !card.borrowed) return null;
  return /* @__PURE__ */ jsxs2("div", { className: "flex flex-col gap-1.5", children: [
    card.blurb ? /* @__PURE__ */ jsx2(Copy, { html: card.blurb, className: "doc-blurb" }) : null,
    card.borrowed ? /* @__PURE__ */ jsx2("p", { className: "font-mono text-[11px] text-apt-text-dim", children: /* @__PURE__ */ jsx2(Source, { lead: "Borrowed from", from: card.borrowed }) }) : null
  ] });
}
function Screenshots({ card }) {
  if (!card.screenshots.length) return null;
  return /* @__PURE__ */ jsx2(Panel, { title: "Screenshots", icon: ImageIcon, hue: "success", children: card.screenshots.map((shot) => /* @__PURE__ */ jsxs2("figure", { className: "flex flex-col gap-2", children: [
    /* @__PURE__ */ jsx2(
      "img",
      {
        src: shot.src,
        alt: shot.alt,
        loading: "lazy",
        className: "h-auto w-full rounded-md border border-apt-border"
      }
    ),
    shot.caption ? /* @__PURE__ */ jsx2("figcaption", { className: "text-sm text-apt-text-dim", children: shot.caption }) : null
  ] }, shot.src)) });
}
function Api({ card }) {
  if (!card.api.length) return null;
  return /* @__PURE__ */ jsx2(Panel, { title: "API", icon: Braces, hue: "blue", children: /* @__PURE__ */ jsx2(Blocks, { html: card.api }) });
}
function Links({ card, title }) {
  if (!card.links.length) return null;
  return /* @__PURE__ */ jsx2(Panel, { title, icon: Link22, hue: "accent", children: /* @__PURE__ */ jsx2("ul", { className: "flex flex-col gap-2.5", children: card.links.map((link) => /* @__PURE__ */ jsx2(LinkRow, { link }, `${link.kind}:${link.url}:${link.name}`)) }) });
}
function Tech({ card }) {
  const hasTech = card.tech.stack.length > 0 || card.tech.notes.length > 0;
  return hasTech ? /* @__PURE__ */ jsx2(TechDetail, { tech: card.tech }) : null;
}
function paneLabel(part) {
  if (part === "overview") return "Overview";
  return TUTORIAL_PARTS.find((p) => p.id === part).label;
}
function TutorialPane({
  card,
  tutorial,
  descriptionTitle
}) {
  const label = paneLabel(tutorial.part);
  const action = tutorial.part === "overview" && tutorial.api.length ? /* @__PURE__ */ jsx2(
    ApiButton,
    {
      readOnly: true,
      label: "API",
      size: "sm",
      title: `API: ${card.name}`,
      highlight: tutorial.api,
      highlightLabel: "This tutorial",
      intro: /* @__PURE__ */ jsx2(Blocks, { html: card.api })
    }
  ) : void 0;
  let body;
  switch (tutorial.part) {
    case "overview":
      body = /* @__PURE__ */ jsxs2(Fragment, { children: [
        /* @__PURE__ */ jsx2(Blurb, { card }),
        tutorial.lead.length ? /* @__PURE__ */ jsx2(Panel, { title: descriptionTitle, icon: BookOpenText, hue: "blue", children: /* @__PURE__ */ jsx2(Blocks, { html: tutorial.lead }) }) : null,
        /* @__PURE__ */ jsx2(Screenshots, { card }),
        tutorial.api.length ? null : /* @__PURE__ */ jsx2(Api, { card }),
        /* @__PURE__ */ jsx2(Links, { card, title: "References" }),
        /* @__PURE__ */ jsx2(Tech, { card })
      ] });
      break;
    case "definitions":
      body = /* @__PURE__ */ jsx2(
        Panel,
        {
          title: label,
          icon: Quote,
          hue: "accent",
          footnote: /* @__PURE__ */ jsx2(Source, { lead: "Every term is in the", from: tutorial.glossary }),
          children: /* @__PURE__ */ jsx2("dl", { className: "flex flex-col gap-3", "data-testid": "tutorial-terms", children: tutorial.terms.map((term) => /* @__PURE__ */ jsx2(TermBlock, { term, href: `${tutorial.glossary.href}#${term.id}` }, term.id)) })
        }
      );
      break;
    case "steps":
      body = /* @__PURE__ */ jsx2(
        TutorialSteps,
        {
          tutorialId: tutorial.id,
          steps: tutorial.steps,
          title: label,
          icon: glyph(ListChecks, "blue")
        }
      );
      break;
  }
  return /* @__PURE__ */ jsxs2("article", { className: "doc-prose flex flex-col gap-6", "data-pane": tutorial.part, children: [
    /* @__PURE__ */ jsx2(Header, { card, kicker: label, action }),
    body
  ] });
}
function DocumentDetail({
  view,
  card,
  descriptionTitle
}) {
  if (view.tutorial) {
    return /* @__PURE__ */ jsx2(TutorialPane, { card, tutorial: view.tutorial, descriptionTitle });
  }
  if (view.glossary) {
    const { lead } = sectionsOf(card.description);
    return /* @__PURE__ */ jsxs2("article", { className: "doc-prose flex flex-col gap-6", "data-pane": "glossary", children: [
      /* @__PURE__ */ jsx2(Header, { card }),
      /* @__PURE__ */ jsx2(Blurb, { card }),
      lead.length ? /* @__PURE__ */ jsx2(Panel, { title: descriptionTitle, icon: BookOpenText, hue: "blue", children: /* @__PURE__ */ jsx2(Blocks, { html: lead }) }) : null,
      /* @__PURE__ */ jsx2(
        GlossarySearch,
        {
          terms: view.glossary.terms,
          tutorials: view.glossary.tutorials,
          title: "Terms",
          icon: glyph(Book, "accent")
        }
      ),
      /* @__PURE__ */ jsx2(Links, { card, title: "Links" })
    ] });
  }
  return /* @__PURE__ */ jsxs2("article", { className: "doc-prose flex flex-col gap-6", children: [
    /* @__PURE__ */ jsx2(Header, { card }),
    /* @__PURE__ */ jsx2(Blurb, { card }),
    card.description.length ? /* @__PURE__ */ jsx2(Panel, { title: descriptionTitle, icon: BookOpenText, hue: "blue", children: /* @__PURE__ */ jsx2(Blocks, { html: card.description }) }) : null,
    /* @__PURE__ */ jsx2(Screenshots, { card }),
    /* @__PURE__ */ jsx2(Api, { card }),
    /* @__PURE__ */ jsx2(Links, { card, title: "Links" }),
    /* @__PURE__ */ jsx2(Tech, { card })
  ] });
}

// src/help/document/DocumentSurface.tsx
import { jsx as jsx3 } from "react/jsx-runtime";
var KIND_ICON = {
  glossary: Book2,
  tutorial: GraduationCap,
  definitions: Quote2,
  steps: ListChecks2
};
function itemIcon(item, depth) {
  if (item.id === OVERVIEW_ID) return /* @__PURE__ */ jsx3(Info, { size: 16, "aria-hidden": true });
  if (item.kind) {
    const Icon = KIND_ICON[item.kind];
    return /* @__PURE__ */ jsx3(Icon, { size: 16, "aria-hidden": true });
  }
  if (depth === 0) return /* @__PURE__ */ jsx3(LayoutGrid, { size: 16, "aria-hidden": true });
  if (item.opens) return /* @__PURE__ */ jsx3(Folder, { size: 16, "aria-hidden": true });
  return /* @__PURE__ */ jsx3(FileText, { size: 16, "aria-hidden": true });
}
function routeItem(doc, item, depth) {
  return {
    id: item.id,
    label: item.label,
    href: doc.href(item.open),
    icon: itemIcon(item, depth),
    dividerAfter: Boolean(item.section || item.divider),
    dividerLabel: item.section,
    // A row with an Overview of its own opens on it, so warm that page as well as the list.
    prefetch: item.overview ? [doc.href([...item.open, OVERVIEW_ID])] : void 0
  };
}
function routeLevel(doc, rail, depth) {
  return {
    key: rail.id,
    title: rail.title,
    items: rail.items.map((item) => routeItem(doc, item, depth)),
    selectedId: rail.selectedId,
    defaultSelectedId: rail.overview ? OVERVIEW_ID : void 0,
    clearHref: doc.href(rail.above),
    itemNoun: "entry",
    overviewHelp: "Choose an entry from the list to read it here."
  };
}
function DocumentSurface({ doc, view }) {
  const levels = view.rails.map((rail, depth) => routeLevel(doc, rail, depth));
  return /* @__PURE__ */ jsx3(
    HelpMasterDetail,
    {
      levels,
      rootLabel: doc.title,
      detailTitle: view.entry?.label ?? null,
      ssrDetail: true,
      children: view.card ? /* @__PURE__ */ jsx3(DocumentDetail, { view, card: view.card, descriptionTitle: doc.descriptionTitle }) : null
    }
  );
}

// src/help/document/documentRoute.tsx
import { notFound } from "next/navigation";
import { canonicalOnly } from "@adh-sdk/adh-registry/seo";
import { jsx as jsx4 } from "react/jsx-runtime";
function documentRoute(doc) {
  function generateStaticParams() {
    return [{ path: [] }, ...doc.paths().map((path) => ({ path }))];
  }
  async function generateMetadata(props) {
    const { path = [] } = await props.params;
    const view = doc.view(path);
    if (!view) return {};
    const title = view.title;
    return { ...canonicalOnly(doc.href(view.canonical)), title };
  }
  async function Page(props) {
    const { path = [] } = await props.params;
    const view = doc.view(path);
    if (!view) notFound();
    return /* @__PURE__ */ jsx4(DocumentSurface, { doc, view });
  }
  return { generateStaticParams, generateMetadata, Page };
}
export {
  DocumentDetail,
  DocumentSurface,
  OVERVIEW_ID,
  TUTORIAL_PARTS,
  contentDocument,
  documentRoute,
  glossaryOf,
  nextOpen,
  plainText,
  progressKey,
  readProgress,
  sectionsOf,
  slugOf,
  startOf,
  termMatches,
  termsFor,
  toggle,
  tutorialLinks
};
//# sourceMappingURL=index.js.map