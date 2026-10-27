// src/landing/LandingDeck.tsx
import {
  Deck,
  DeckScript,
  Head,
  Hero,
  indexRows,
  renderBlock,
  Screen,
  TourStrip,
  Wrap
} from "@agenticdevelopertoolkit/landing";
import { NavChrome } from "@agenticdevelopertoolkit/landing/client";

// src/landing/tour.ts
import { siteProdUrl } from "@agentic-toolkit/adh-registry";
var TOUR_SCREEN_ID = "tour";
function tourStep(edge) {
  if (edge === void 0) return void 0;
  return { href: siteProdUrl(edge.site, "/tour"), label: edge.label, note: edge.note };
}

// src/landing/LandingDeck.tsx
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
function renderSection(section, key) {
  return /* @__PURE__ */ jsx(Screen, { id: section.id, children: /* @__PURE__ */ jsxs(Wrap, { children: [
    section.headingInBlock === true ? null : /* @__PURE__ */ jsx(Head, { eyebrow: section.eyebrow, title: section.title }),
    section.blocks.map((block, i) => renderBlock(block, i))
  ] }) }, key);
}
function deck(content, lead, leadRow) {
  const rows = leadRow === void 0 ? indexRows(content) : [leadRow, ...indexRows(content)];
  return /* @__PURE__ */ jsxs(Fragment, { children: [
    /* @__PURE__ */ jsx(DeckScript, {}),
    /* @__PURE__ */ jsxs(Deck, { children: [
      /* @__PURE__ */ jsx(NavChrome, { navLabel: "Sections", links: rows }),
      lead,
      /* @__PURE__ */ jsx(
        Hero,
        {
          mark: /* @__PURE__ */ jsx("img", { src: "/glyph.svg", alt: "" }),
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
  const lead = /* @__PURE__ */ jsx(
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
import {
  Band,
  DeckScript as DeckScript2,
  Flow,
  FlowHero,
  Head as Head2,
  heroSlots,
  indexRows as indexRows2,
  joinMeta,
  renderBlock as renderBlock2,
  TourStrip as TourStrip2
} from "@agenticdevelopertoolkit/landing";
import { NavChrome as NavChrome2, Reveal } from "@agenticdevelopertoolkit/landing/client";
import { Fragment as Fragment2, jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var TONES = ["soft", "dark"];
function renderBand(section, key) {
  return /* @__PURE__ */ jsx2(Band, { id: section.id, tone: TONES[key % TONES.length], children: /* @__PURE__ */ jsxs2(Reveal, { children: [
    section.headingInBlock === true ? null : /* @__PURE__ */ jsx2(Head2, { eyebrow: section.eyebrow, title: section.title }),
    section.blocks.map((block, i) => renderBlock2(block, i))
  ] }) }, key);
}
function flow(content, lead, leadRow, heroFillsWindow) {
  const rows = leadRow === void 0 ? indexRows2(content) : [leadRow, ...indexRows2(content)];
  const { actions, meta, status } = heroSlots(content.hero);
  if (status !== void 0) {
    throw new Error(
      `LandingFlow: a 'StatusPill' block has no slot in the flow hero \u2014 only 'Cta' and 'Trust' do. Move it into a section, or render this page as a LandingDeck.`
    );
  }
  return /* @__PURE__ */ jsxs2(Fragment2, { children: [
    /* @__PURE__ */ jsx2(DeckScript2, { armSnapping: false, openAtTop: false }),
    /* @__PURE__ */ jsxs2(Flow, { children: [
      /* @__PURE__ */ jsx2(NavChrome2, { navLabel: "Sections", links: rows }),
      lead,
      /* @__PURE__ */ jsx2(
        FlowHero,
        {
          mark: /* @__PURE__ */ jsx2("img", { src: "/glyph.svg", alt: "" }),
          headline: content.hero.headline,
          sub: content.hero.tagline,
          meta: meta.length === 0 ? void 0 : joinMeta(meta),
          fill: heroFillsWindow,
          children: actions.length === 0 ? void 0 : actions
        }
      ),
      content.sections.map((section, i) => renderBand(section, i))
    ] })
  ] });
}
function LandingFlow({ content, heroFillsWindow = false }) {
  return flow(content, null, void 0, heroFillsWindow);
}
function LandingFlowTour({ content, heroFillsWindow = false }) {
  const { tour } = content;
  if (tour === void 0) return flow(content, null, void 0, heroFillsWindow);
  const lead = /* @__PURE__ */ jsx2(
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
  return flow(content, lead, { href: `#${TOUR_SCREEN_ID}`, label: tour.eyebrow }, heroFillsWindow);
}

// src/landing/index.ts
import {
  landingFromData
} from "@agenticdevelopertoolkit/landing";
export {
  LandingDeck,
  LandingFlow,
  LandingFlowTour,
  LandingTour,
  landingFromData
};
//# sourceMappingURL=index.js.map