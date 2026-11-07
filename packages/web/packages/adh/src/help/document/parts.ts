/**
 * How a tutorials document is read out of the cards content-buildr writes. Pure: no React, no
 * Next, so the model and its tests use it alike.
 *
 * A tutorial's card is split into the panes its list shows, by a convention the
 * fishlamp-tutorial-writer skill documents and nothing else needs to know:
 *
 * - **Overview**: the blurb, then the `## Description` prose before its first `###`, then the
 *   card's `## Links` as its References and a button onto the API explorer showing the routes
 *   the card's `## API` names (see `apiRoutesOf`).
 * - **Definitions**: the glossary's terms that link to the tutorial.
 * - **Steps**: each `###` section of `## Description`, its heading the step's title.
 *
 * The glossary is one entry of the same document. Each `###` section of its `## Description` is a
 * term, and a term's related tutorials are the ones its closing `Tutorials:` paragraph links to.
 * One definition per term, read by both the Glossary pane and every tutorial's Definitions pane.
 */

/** A pane of a tutorial, after its Overview. */
export type TutorialPart = "definitions" | "steps";

/** The panes a tutorial's list offers after its Overview, in order. */
export const TUTORIAL_PARTS: readonly { id: TutorialPart; label: string }[] = [
  { id: "definitions", label: "Definitions" },
  { id: "steps", label: "Steps" },
];

/** One `###` section of a card's description. */
export interface DocSection {
  /** A stable id for the section, from its heading's text. */
  id: string;
  /** The heading as plain text. */
  title: string;
  /** The heading's own rendered HTML, which may hold code or links. */
  titleHtml: string;
  /** The blocks under the heading, up to the next one. */
  html: string[];
}

/** One action within a step: an item of the step's numbered list. */
export interface Substep {
  /** `<step id>/<slug of the item's first words>`, deduped within the step. */
  id: string;
  /** The item's rendered HTML. */
  html: string;
}

/**
 * One step of a tutorial. A step whose body holds a numbered list of two or more items has those
 * items as its sub-steps, each ticked on its own; `before` and `after` are the blocks either side
 * of that list. A step with no such list has no sub-steps, and its blocks are all in `before`.
 */
export interface TutorialStep extends DocSection {
  before: string[];
  substeps: Substep[];
  /** The number the list's first item carries, from its `start` attribute; 1 when it has none. */
  start: number;
  after: string[];
}

/** One term of the glossary. */
export interface GlossaryTerm extends DocSection {
  /** The definition as plain text, for searching. */
  text: string;
  /** The ids of the tutorials the definition links to, in the order it names them. */
  tutorials: string[];
}

const HEADING = /^\s*<h3(?:\s[^>]*)?>([\s\S]*?)<\/h3>\s*$/;
/** The named entities markdown renderers write. Numeric references are decoded in general. */
const ENTITIES: Record<string, string> = {
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
  ldquo: "\u201c",
  rdquo: "\u201d",
  laquo: "\u00ab",
  raquo: "\u00bb",
  middot: "\u00b7",
  bull: "\u2022",
  times: "\u00d7",
  larr: "\u2190",
  rarr: "\u2192",
  copy: "\u00a9",
  reg: "\u00ae",
  trade: "\u2122",
};

/** One entity as its character. One this does not know is left as written, never deleted. */
function decodeEntity(entity: string, body: string): string {
  if (body[0] === "#") {
    const code = body[1] === "x" || body[1] === "X" ? parseInt(body.slice(2), 16) : parseInt(body.slice(1), 10);
    return Number.isInteger(code) && code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : entity;
  }
  return ENTITIES[body] ?? entity;
}

/** Markup as the words a reader sees. */
export function plainText(html: string): string {
  return html
    .replace(/<[^>]*>/g, "")
    .replace(/&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);/g, decodeEntity)
    .replace(/\s+/g, " ")
    .trim();
}

/** A lowercase, hyphenated id from a heading's words. */
export function slugOf(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/** A description's blocks split at each `###`: the prose before the first one, and each section. */
export function sectionsOf(blocks: readonly string[]): { lead: string[]; sections: DocSection[] } {
  const lead: string[] = [];
  const sections: DocSection[] = [];
  const used = new Set<string>();
  for (const block of blocks) {
    const heading = HEADING.exec(block);
    if (heading) {
      const titleHtml = (heading[1] ?? "").trim();
      const title = plainText(titleHtml);
      const base = slugOf(title) || "section";
      // Two sections must never share an id, or a saved step would tick both. The suffix is
      // checked against every id given so far, since a title like "Save 2" claims "save-2" itself.
      let id = base;
      for (let n = 2; used.has(id); n++) id = `${base}-${n}`;
      used.add(id);
      sections.push({ id, title, titleHtml, html: [] });
    } else if (sections.length) {
      sections.at(-1)!.html.push(block);
    } else {
      lead.push(block);
    }
  }
  return { lead, sections };
}

const ORDERED = /^\s*<ol(?:\s[^>]*)?>([\s\S]*)<\/ol>\s*$/;

/** The number an `<ol>` block's first item carries. */
function listStart(block: string): number {
  const start = /^\s*<ol\s[^>]*\bstart="?(\d+)/.exec(block);
  return start ? Number(start[1]) : 1;
}

/** The top-level items of a list's inner HTML, an item's own nested lists kept inside it. */
export function listItems(inner: string): string[] {
  const items: string[] = [];
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

/** The words a sub-step's id is made from, at most this many. */
const SUBSTEP_ID_WORDS = 6;

/**
 * A step's list items as sub-steps, each id made from the item's own words: its text up to the
 * first nested list, code block or quote, the first few words slugged. An id by position would
 * move a saved tick onto a neighbour when an item is added or removed above it; an id by content
 * keeps the ticks on unchanged items, and only an item whose words changed starts unticked
 * (readProgress drops ids it no longer knows). Two items with the same words take -2, -3, ….
 */
function substepsOf(stepId: string, items: readonly string[]): Substep[] {
  const used = new Set<string>();
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

/**
 * A section as a tutorial step: its first numbered list of two or more items is its sub-steps.
 * A code fence written between two items, not indented under the first, ends the list in
 * markdown, and the items after it come out as a second `<ol start="N">` numbered on from the
 * first. That second list is the same list, so it is read back in, and the blocks between the
 * two belong to the item before them.
 */
export function stepOf(section: DocSection): TutorialStep {
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
      after: blocks.slice(end),
    };
  }
  return { ...section, before: blocks, substeps: [], start: 1, after: [] };
}

/** The ids of the tutorials `html` links to, from `/tutorials/<id>` links under `base`. */
export function tutorialLinks(html: string, base: string, known: ReadonlySet<string>): string[] {
  const out: string[] = [];
  const escaped = base.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const href = new RegExp(`href="${escaped}/([^"/#?]+)`, "g");
  for (const match of html.matchAll(href)) {
    const id = match[1];
    if (id && known.has(id) && !out.includes(id)) out.push(id);
  }
  return out;
}

/**
 * Whether a block is a term's closing paragraph that names its tutorials:
 * `Tutorials: [One](/tutorials/one), …`. Read by its words, so `**Tutorials:**` or a paragraph
 * with attributes counts as well.
 */
function isTutorialsLine(block: string): boolean {
  return /^\s*<p[\s>]/.test(block) && plainText(block).startsWith("Tutorials:");
}

/**
 * The glossary's terms, read from its card's description. A term's tutorials are the links in its
 * closing `Tutorials:` paragraph, which is lifted out of the definition because the panes that
 * show a term list its tutorials themselves. A link to a tutorial anywhere else in a definition
 * is prose, and does not count.
 */
export function glossaryOf(
  description: readonly string[],
  base: string,
  tutorialIds: ReadonlySet<string>,
): GlossaryTerm[] {
  const { sections } = sectionsOf(description);
  return sections.map((section) => {
    const line = [...section.html].reverse().find(isTutorialsLine);
    const html = section.html.filter((block) => block !== line);
    return {
      ...section,
      html,
      text: plainText(html.join(" ")),
      tutorials: line ? tutorialLinks(line, base, tutorialIds) : [],
    };
  });
}

/** The glossary's terms that a tutorial's Definitions pane shows. */
export function termsFor(terms: readonly GlossaryTerm[], tutorialId: string): GlossaryTerm[] {
  return terms.filter((term) => term.tutorials.includes(tutorialId));
}

/** Whether `term` matches what a reader typed: every word, in its name or its definition. */
export function termMatches(term: Pick<GlossaryTerm, "title" | "text">, query: string): boolean {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return true;
  const haystack = `${term.title} ${term.text}`.toLowerCase();
  return words.every((word) => haystack.includes(word));
}

/** A route a tutorial's `## API` names: its path, and its method when the prose gives one. */
export interface ApiRoute {
  method?: string;
  path: string;
}

const METHODS = new Set(["GET", "POST", "PUT", "PATCH", "DELETE"]);

/**
 * The routes a card's `## API` names, in order. content-buildr wants a method in code of its own,
 * so the prose reads "a `GET` or `PUT` of `/ecosystem/client-auth/{id}`": each method code waits
 * for the next code that starts with `/` in the same block, and is that route's method. A code
 * span may also hold both, as `GET /auth/me`. A path with no method before it stands for every
 * method on that path. A query string or fragment is not part of the route.
 */
export function apiRoutesOf(blocks: readonly string[]): ApiRoute[] {
  const out: ApiRoute[] = [];
  const seen = new Set<string>();
  const add = (methods: readonly (string | undefined)[], text: string): void => {
    const path = text.split(/[?#]/)[0] ?? text;
    for (const method of methods) {
      const key = `${method ?? "*"} ${path}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(method ? { method, path } : { path });
    }
  };
  for (const block of blocks) {
    // A method names the route after it in its own sentence; it never reaches into the next block.
    let pending: string[] = [];
    let last: string | null = null;
    for (const match of block.matchAll(/<code>([\s\S]*?)<\/code>/g)) {
      const text = plainText(match[1] ?? "");
      const upper = text.toUpperCase();
      if (METHODS.has(upper)) {
        // "a `POST` to it": the method names the path just before it, not the next one.
        const after = block.slice((match.index ?? 0) + match[0].length);
        if (last && /^\s*(?:to|of|on|from)\s+it\b/i.test(plainText(after.split("<code>")[0] ?? ""))) {
          add([upper], last);
          continue;
        }
        pending.push(upper);
        continue;
      }
      const both = /^([A-Za-z]+)\s+(\/\S*)$/.exec(text);
      if (both && METHODS.has(both[1]!.toUpperCase())) {
        add([both[1]!.toUpperCase()], both[2]!);
        last = both[2]!.split(/[?#]/)[0] ?? both[2]!;
        pending = [];
        continue;
      }
      if (!text.startsWith("/")) continue;
      add(pending.length ? pending : [undefined], text);
      last = text.split(/[?#]/)[0] ?? text;
      pending = [];
    }
  }
  return out;
}
