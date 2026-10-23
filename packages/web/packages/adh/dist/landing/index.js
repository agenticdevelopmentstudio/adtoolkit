// src/landing/LandingDeck.tsx
import { Deck, DeckScript, Head, Hero, Screen, TourStrip, Wrap } from "@agenticdevelopertoolkit/landing";
import { NavChrome } from "@agenticdevelopertoolkit/landing/client";

// src/landing/blocks.tsx
import { siteProdUrl } from "@agentic-toolkit/adh-registry";
import {
  Btn,
  Card,
  Cards,
  Checklist,
  Chips,
  Closer,
  Code,
  Cta,
  Faq,
  Lede,
  Points,
  Roadmap,
  Rule,
  Shot,
  Stats,
  StatusPill,
  Table,
  Trust,
  Versus
} from "@agenticdevelopertoolkit/landing";
import { jsx } from "react/jsx-runtime";
var TOUR_SCREEN_ID = "tour";
function prose(paragraphs) {
  return paragraphs.map((text, i) => /* @__PURE__ */ jsx("p", { children: text }, i));
}
function renderBlock(block, key) {
  switch (block.kind) {
    case "Lede":
      return /* @__PURE__ */ jsx(Lede, { children: block.children }, key);
    case "Trust":
      return /* @__PURE__ */ jsx(Trust, { items: block.items }, key);
    case "Cards":
      return /* @__PURE__ */ jsx(Cards, { pair: block.pair, trio: block.trio, children: block.items.map((card, i) => /* @__PURE__ */ jsx(Card, { kicker: card.kicker, title: card.title, children: prose(card.body) }, i)) }, key);
    case "Points":
      return /* @__PURE__ */ jsx(Points, { entries: block.entries, ordered: block.ordered }, key);
    case "Code":
      return /* @__PURE__ */ jsx(Code, { text: block.text }, key);
    case "Shot":
      return /* @__PURE__ */ jsx(
        Shot,
        {
          title: block.title,
          caption: block.caption,
          pendingLabel: "Screenshot coming soon",
          ...block.src === void 0 ? {} : { media: /* @__PURE__ */ jsx("img", { src: `/screenshots/${block.src}.png`, alt: block.caption }) }
        },
        key
      );
    case "Table":
      return /* @__PURE__ */ jsx(Table, { caption: block.caption, columns: block.columns, rows: block.rows }, key);
    case "StatusPill":
      return /* @__PURE__ */ jsx(StatusPill, { free: block.free, children: block.children }, key);
    case "Rule":
      return /* @__PURE__ */ jsx(Rule, { steps: block.steps }, key);
    case "Stats":
      return /* @__PURE__ */ jsx(Stats, { entries: block.entries }, key);
    case "Versus":
      return /* @__PURE__ */ jsx(Versus, { them: block.them, us: block.us }, key);
    case "Chips":
      return /* @__PURE__ */ jsx(Chips, { entries: block.entries, soon: block.soon }, key);
    case "Checklist":
      return /* @__PURE__ */ jsx(Checklist, { groups: block.groups }, key);
    case "Faq":
      return /* @__PURE__ */ jsx(
        Faq,
        {
          entries: block.entries.map((entry) => ({
            question: entry.question,
            answer: prose(entry.answer),
            open: entry.open
          }))
        },
        key
      );
    case "Closer":
      return /* @__PURE__ */ jsx(Closer, { title: block.title, children: prose(block.body) }, key);
    case "Cta":
      return /* @__PURE__ */ jsx(Cta, { children: block.buttons.map((button, i) => /* @__PURE__ */ jsx(Btn, { href: button.href, variant: button.variant, children: button.label }, i)) }, key);
    case "Roadmap":
      return /* @__PURE__ */ jsx(Roadmap, { eyebrow: block.eyebrow, children: block.children.map((child, i) => renderBlock(child, i)) }, key);
    default: {
      const unhandled = block;
      return unhandled;
    }
  }
}
function indexRows(content) {
  return content.sections.map((section) => ({
    href: `#${section.id}`,
    label: section.eyebrow
  }));
}
function tourStep(edge) {
  if (edge === void 0) return void 0;
  return { href: siteProdUrl(edge.site, "/tour"), label: edge.label, note: edge.note };
}

// src/landing/LandingDeck.tsx
import { Fragment, jsx as jsx2, jsxs } from "react/jsx-runtime";
function renderSection(section, key) {
  return /* @__PURE__ */ jsx2(Screen, { id: section.id, children: /* @__PURE__ */ jsxs(Wrap, { children: [
    section.headingInBlock === true ? null : /* @__PURE__ */ jsx2(Head, { eyebrow: section.eyebrow, title: section.title }),
    section.blocks.map((block, i) => renderBlock(block, i))
  ] }) }, key);
}
function deck(content, lead, leadRow) {
  const rows = leadRow === void 0 ? indexRows(content) : [leadRow, ...indexRows(content)];
  return /* @__PURE__ */ jsxs(Fragment, { children: [
    /* @__PURE__ */ jsx2(DeckScript, {}),
    /* @__PURE__ */ jsxs(Deck, { children: [
      /* @__PURE__ */ jsx2(NavChrome, { navLabel: "Sections", links: rows }),
      lead,
      /* @__PURE__ */ jsx2(
        Hero,
        {
          mark: /* @__PURE__ */ jsx2("img", { src: "/glyph.svg", alt: "" }),
          headline: content.hero.headline,
          tagline: content.hero.tagline,
          children: content.hero.blocks.map((block, i) => renderBlock(block, i))
        }
      ),
      content.sections.map((section, i) => renderSection(section, i))
    ] })
  ] });
}
function LandingDeck({ content }) {
  return deck(content, null, void 0);
}
function LandingTour({ content }) {
  const { tour } = content;
  if (tour === void 0) return deck(content, null, void 0);
  const lead = /* @__PURE__ */ jsx2(
    TourStrip,
    {
      eyebrow: tour.eyebrow,
      promise: tour.promise,
      position: tour.position,
      pillars: tour.pillars,
      back: tourStep(tour.back),
      next: tourStep(tour.next)
    }
  );
  return deck(content, lead, { href: `#${TOUR_SCREEN_ID}`, label: tour.eyebrow });
}

// src/landing/LandingFlow.tsx
import { Band, Btn as Btn2, DeckScript as DeckScript2, Flow, FlowHero, Head as Head2, TourStrip as TourStrip2 } from "@agenticdevelopertoolkit/landing";
import { NavChrome as NavChrome2, Reveal } from "@agenticdevelopertoolkit/landing/client";
import { Fragment as Fragment2, jsx as jsx3, jsxs as jsxs2 } from "react/jsx-runtime";
var TONES = ["soft", "dark"];
function renderBand(section, key) {
  return /* @__PURE__ */ jsx3(Band, { id: section.id, tone: TONES[key % TONES.length], children: /* @__PURE__ */ jsxs2(Reveal, { children: [
    section.headingInBlock === true ? null : /* @__PURE__ */ jsx3(Head2, { eyebrow: section.eyebrow, title: section.title }),
    section.blocks.map((block, i) => renderBlock(block, i))
  ] }) }, key);
}
function heroSlots(hero) {
  const actions = [];
  const meta = [];
  hero.blocks.forEach((block) => {
    switch (block.kind) {
      case "Cta":
        block.buttons.forEach(
          (button) => actions.push(
            /* @__PURE__ */ jsx3(Btn2, { href: button.href, variant: button.variant, children: button.label }, actions.length)
          )
        );
        return;
      case "Trust":
        meta.push(...block.items);
        return;
      default:
        throw new Error(
          `LandingFlow: a '${block.kind}' block has no slot in the flow hero \u2014 only 'Cta' and 'Trust' do. Move it into a section, or render this page as a LandingDeck.`
        );
    }
  });
  return { actions, meta };
}
function joined(items) {
  return items.map((item, i) => /* @__PURE__ */ jsxs2("span", { children: [
    i > 0 ? " \xB7 " : null,
    item
  ] }, i));
}
function flow(content, lead, leadRow) {
  const rows = leadRow === void 0 ? indexRows(content) : [leadRow, ...indexRows(content)];
  const { actions, meta } = heroSlots(content.hero);
  return /* @__PURE__ */ jsxs2(Fragment2, { children: [
    /* @__PURE__ */ jsx3(DeckScript2, { armSnapping: false, openAtTop: false }),
    /* @__PURE__ */ jsxs2(Flow, { children: [
      /* @__PURE__ */ jsx3(NavChrome2, { navLabel: "Sections", links: rows }),
      lead,
      /* @__PURE__ */ jsx3(
        FlowHero,
        {
          mark: /* @__PURE__ */ jsx3("img", { src: "/glyph.svg", alt: "" }),
          headline: content.hero.headline,
          sub: content.hero.tagline,
          meta: meta.length === 0 ? void 0 : joined(meta),
          children: actions.length === 0 ? void 0 : actions
        }
      ),
      content.sections.map((section, i) => renderBand(section, i))
    ] })
  ] });
}
function LandingFlow({ content }) {
  return flow(content, null, void 0);
}
function LandingFlowTour({ content }) {
  const { tour } = content;
  if (tour === void 0) return flow(content, null, void 0);
  const lead = /* @__PURE__ */ jsx3(
    TourStrip2,
    {
      eyebrow: tour.eyebrow,
      promise: tour.promise,
      position: tour.position,
      pillars: tour.pillars,
      back: tourStep(tour.back),
      next: tourStep(tour.next)
    }
  );
  return flow(content, lead, { href: `#${TOUR_SCREEN_ID}`, label: tour.eyebrow });
}

// src/landing/fromData.ts
import { createElement, Fragment as Fragment3 } from "react";
function landingFromData(data, options = {}) {
  return revive(data, options);
}
function revive(value, options) {
  if (Array.isArray(value)) return value.map((v) => revive(v, options));
  if (value === null || typeof value !== "object") return value;
  if ("$inline" in value) {
    const nodes = value.$inline;
    return createElement(Fragment3, null, ...nodes.map((n) => node(n, options)));
  }
  const out = {};
  for (const [key, v] of Object.entries(value)) {
    if (!key.startsWith("$")) out[key] = revive(v, options);
  }
  return out;
}
function node(n, options) {
  if (typeof n === "string") return n;
  const children = n.c.map((c) => node(c, options));
  switch (n.t) {
    case "link":
      return createElement(options.link ?? "a", { href: n.href }, ...children);
    case "a":
      return createElement("a", { href: n.href }, ...children);
    default:
      return createElement(n.t, null, ...children);
  }
}
export {
  LandingDeck,
  LandingFlow,
  LandingFlowTour,
  LandingTour,
  landingFromData
};
//# sourceMappingURL=index.js.map