import type { ComponentType } from 'react'
import type { BandTone } from '@agenticdevelopertoolkit/landing'

/**
 * One piece of a site's copy. A plain string is text; `{ html }` is words that carry emphasis
 * or a link, as the markup content-buildr rendered from the site's own markdown.
 */
export type CopyText = string | { html: string }

/** How the hero draws its `Shot`: the kit's full-width shot bled off the page, or a small one. */
export type HeroShotLook = 'bleed' | 'thumbnail'

/**
 * Everything a site SAYS that is not the landing page's body: its name and description for
 * the metadata, the wordmark in the bar, the drawer's foot and the page footer. It is the
 * site's `copy` content, generated from its markdown; the frame reads it and never words
 * anything itself.
 */
export interface FrameCopy {
  name: string
  description: string
  /** The browser tab's title, when it is not the name. */
  title?: string
  /** The metadata's keywords, when the site words any. */
  keywords?: string[]
  /** The wordmark in the bar. */
  brand: CopyText
  markAlt: string
  ogImageAlt: string
  people: { author: string; creator: string; publisher: string }
  contact: { email: string }
  /**
   * The drawer's own rows, in the site's words: the Home row's label, and — when the site words
   * one — a last row that mails `contact.email`. Plain strings, since a drawer row is a link's
   * text (the landing kit's `NavLink.label`). `action`, when worded, is the one button the bar
   * carries beside the burger: a paragraph that is only a link, so `{ label, href }`. `extra`
   * words the config's `drawerExtra` rows, each by the name its row gives as `nav`.
   */
  nav: {
    home: string
    contact?: string
    action?: { label: string; href: string }
    extra?: Record<string, string>
  }
  /** What the page calls a screenshot not yet taken. Absent: the landing kit's own word. */
  screenshotPending?: string
  /** The drawer's foot: a hello above the mail address and, when worded, a byline below it. */
  drawer?: { hello: CopyText; byline?: CopyText }
  /** The page footer's lines, in order. Absent: the page has no footer. */
  footer?: Record<string, CopyText>
  /**
   * The 404's words, when the site has its own: the tab's whole title, the status code shown as
   * a caption above the heading, the heading, the body, and the label of the link back to `/`.
   * Absent: the 404 says what Next's built-in one does.
   */
  notFound?: { title: string; code: string; heading: string; body: CopyText; back: string }
}

/**
 * What a site CONFIGURES about the frame: facts rather than words, from its `site.json`.
 */
export interface FrameConfig {
  siteUrl: string
  mark: { src: string; shape: 'glyph' | 'app-icon' }
  themeColor: string
  ogImage: string
  /** The OG image's pixel size, when the site states it: unfurlers lay the card out before it loads. */
  ogImageSize?: { width: number; height: number }
  /** The OG image's media type (`image/jpeg`), when the site states it: `og:image:type`. */
  ogImageType?: string
  /** The author's own page, when the site names one: the author's `url`, and `<link rel="author">`. */
  authorUrl?: string
  /**
   * Drawer rows after the section rows — a route of the site's own, say. Where each goes is
   * config; what it says is copy: `nav` names its label under the copy's `nav.extra`.
   */
  drawerExtra: { href: string; nav: string }[]
  jsonLd?: object
  /** Paths, beyond `/`, the sitemap lists. */
  sitemap: string[]
  /** The bands that step out of the alternation, by section id. */
  bands?: Record<string, BandLook>
  /** How the hero draws its `Shot` (hero-thumb.tsx); the frame bleeds it when absent. */
  heroShot?: HeroShotLook
}

/**
 * How one band departs from the frame's soft/dark alternation: its own tone — `paper`, the
 * kit's once-a-page punctuation, being the usual reason — or no seam, for a band whose
 * neighbour above is its own tone. What it leaves out keeps the alternation's.
 */
export interface BandLook {
  tone?: BandTone
  seam?: boolean
}

/** One member of the Agentic Developer Hub family, as the shared `family` copy words it. */
export interface FamilyMember {
  name: string
  url: string
  blurb: string
}

/**
 * The shared `family` copy: the band's eyebrow and title, and every member by its id. One file
 * in adhcontent words it for every site, so a member described once reads the same everywhere.
 */
export interface FamilyCopy {
  eyebrow: string
  title: string
  members: Record<string, FamilyMember>
}

/**
 * The family band a site closes `/` with: the shared copy, and `self`, the id of the member that
 * IS this site, which the band leaves out. Generated as `src/site/family.ts` from site.json's
 * `family`.
 */
export interface SiteFamily {
  copy: FamilyCopy
  self: string
}

/**
 * A site's custom components, by the place in the frame each one fills. A slot replaces the
 * CONTENTS of its place and never the frame around it: a hero slot still sits in the
 * window-tall `#top` frame, and a band slot still sits in its band under its `Head`.
 */
export interface SlotMap {
  hero?: ComponentType
  afterHero?: ComponentType
  footer?: ComponentType
  /**
   * bitbag, mounted in the frame's place for him — for a site whose bitbag speaks in its own
   * voice. A component rather than props because a voice carries RegExps, which cannot cross
   * from the server layout into his client-only mount: the site's own `'use client'` module
   * renders `SiteBitbag` with them. Absent: `SiteBitbag` as he comes.
   */
  bitbag?: ComponentType
  /** By section id. A key that names no section is refused rather than ignored. */
  bands: Record<string, ComponentType>
}
