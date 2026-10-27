import type { ReactNode } from 'react'
import type { ChecklistGroup } from '../blocks/Checklist'
import type { ChipEntry } from '../blocks/Chips'
import type { PointEntry } from '../blocks/Points'
import type { RuleStep } from '../blocks/Rule'
import type { StatEntry } from '../blocks/Stats'
import type { VersusSide } from '../blocks/Versus'

/**
 * A landing page, as DATA.
 *
 * A site writes one of these — generated from its markdown by `content-buildr update` into a
 * `landing.json` and loaded through `landingFromData` (./fromData) — and a host layout mounts
 * it. Which is to say: the page's STRUCTURE lives in shared code, and a site carries only its
 * own copy.
 *
 * That split is the whole point. The generator used to emit the markup — a `<Deck>` of
 * `<Screen>`s of `<Wrap>`s, sixty-odd lines per site — so every site held its own copy of
 * the page's shape, and changing the shape meant regenerating every site's files and
 * reviewing every diff to confirm they said the same thing. Now the shape is shared code and
 * a site's generated output holds nothing but its own words.
 *
 * The values are ReactNodes rather than strings because the copy carries markup: a
 * headline's `**bold**` is the accent colour in the deck's heading grammar, and a link in
 * a bullet is a link. The generator writes each as a small node tree in the JSON, and
 * `landingFromData` turns the tree back into a fragment.
 *
 * A host with more to say than a page — adh's tour stop, say — extends this interface and
 * names the wider type to `landingFromData`, which passes every field it does not know
 * through untouched.
 */
export interface LandingPage {
  hero: LandingHero
  sections: LandingSection[]
}

export interface LandingHero {
  headline: ReactNode
  tagline: ReactNode
  /** The rows under the tagline — a button row, a trust row, a status pill. */
  blocks: LandingBlock[]
}

export interface LandingSection {
  /**
   * The `<Screen>`'s DOM id, and the `#href` the deck's index links to. Computed by the
   * generator (`render.screen_id`) rather than derived from `eyebrow` here, so there is
   * one slug function rather than two that agree until one changes — and so the
   * generator's validator can refuse an empty id, a duplicate, or a collision with the
   * tour strip's own `#tour` before anything is written.
   */
  id: string
  /**
   * The screen's label: the `<Head>`'s eyebrow AND the index row that scrolls to it, one
   * field, so a reader who picks "The record" always lands on a screen that says "The
   * record". Two copies of that string is how a hand-kept menu drifts from its page.
   */
  eyebrow: string
  /** The `### ` line under the eyebrow, when the section has one. */
  title?: ReactNode
  /**
   * True when a BLOCK in this section renders the section's heading itself, so the screen
   * carries no `<Head>` of its own. `{roadmap}` is the one that does — it takes the
   * section's heading as its own eyebrow, and a `<Head>` above it would label one screen
   * twice.
   */
  headingInBlock?: true
  blocks: LandingBlock[]
}

/**
 * One block on a screen. `kind` is the exact name this kit exports the component under, and
 * the rest of each member is that component's props — with one deliberate difference,
 * spelled out in `LandingCard`, `LandingFaqEntry` and `Closer` below: a body arrives as a
 * LIST of paragraphs rather than a single node, because the kit styles a body through its
 * `<p>` children (`.lp-card p`, `.lp-closer p`, `.lp-faq details p`) and a body emitted as
 * a bare text child inherits the page's defaults instead.
 */
export type LandingBlock =
  | { kind: 'Lede'; children: ReactNode }
  | { kind: 'Trust'; items: ReactNode[] }
  | { kind: 'Cards'; items: LandingCard[]; pair?: true; trio?: true; wide?: true }
  | { kind: 'Points'; entries: PointEntry[]; ordered?: true }
  | { kind: 'Code'; text: string }
  /** `src` is a screenshot id, not a URL. The page resolves it against the site's own
   *  origin (`/screenshots/<id>.png`) so one image set serves the brochure and the help
   *  site, whose Markdown sanitizer accepts only absolute http/https sources.
   *
   *  OPTIONAL, because `Shot` calls the placeholder its primary state: "until a real
   *  capture exists, every feature section renders one". Required, the page could only ever
   *  emit an `<img>` — and with no `public/screenshots/` anywhere in the fleet that was a
   *  broken image every time, with the frame `Shot` draws for exactly this case
   *  unreachable. Omit `src` until the capture exists; `caption` still says what the shot
   *  will show. */
  | { kind: 'Shot'; src?: string; title: string; caption: string }
  | { kind: 'Table'; caption: ReactNode; columns: ReactNode[]; rows: ReactNode[][] }
  | { kind: 'StatusPill'; children: ReactNode; free?: true }
  | { kind: 'Rule'; steps: RuleStep[] }
  | { kind: 'Stats'; entries: StatEntry[] }
  | { kind: 'Versus'; them: VersusSide; us: VersusSide }
  | { kind: 'Chips'; entries: ChipEntry[]; soon?: true }
  | { kind: 'Checklist'; groups: ChecklistGroup[] }
  | { kind: 'Faq'; entries: LandingFaqEntry[] }
  | { kind: 'Closer'; title: ReactNode; body: ReactNode[] }
  | { kind: 'Cta'; buttons: LandingButton[] }
  | { kind: 'Roadmap'; children: LandingBlock[]; eyebrow?: ReactNode }

export interface LandingCard {
  /** Rendered in its own `<span>` outside the `<h3>`, so a card with one and a card
   *  without still produce the same heading text. */
  kicker?: ReactNode
  /** An icon id, not a URL: the page resolves it to the site's `/icons/<id>.svg`, the
   *  way a `Shot`'s `src` is resolved to `/screenshots/<id>.png`. */
  icon?: string
  title: ReactNode
  body: ReactNode[]
}

export interface LandingFaqEntry {
  question: ReactNode
  answer: ReactNode[]
  open?: boolean
}

export interface LandingButton {
  href: string
  label: ReactNode
  /** Absent reads as `primary`, which is `Btn`'s own default — except beside a hero status
   *  pill, where `heroSlots` renders every button `ghost`. */
  variant?: 'primary' | 'ghost'
}
