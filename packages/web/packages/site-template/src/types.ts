import type { ComponentType } from 'react'

/**
 * One piece of a site's copy. A plain string is text; `{ html }` is words that carry emphasis
 * or a link, as the markup content-buildr rendered from the site's own markdown.
 */
export type CopyText = string | { html: string }

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
  /** The wordmark in the bar. */
  brand: CopyText
  markAlt: string
  ogImageAlt: string
  people: { author: string; creator: string; publisher: string }
  contact: { email: string }
  /**
   * The drawer's own rows, in the site's words: the Home row's label, and — when the site words
   * one — a last row that mails `contact.email`. Plain strings, since a drawer row is a link's
   * text (the landing kit's `NavLink.label`).
   */
  nav: { home: string; contact?: string }
  /** The drawer's foot: a hello above the mail address, a byline below it. */
  drawer?: { hello: CopyText; byline: CopyText }
  /** The page footer's lines, in order. Absent: the page has no footer. */
  footer?: Record<string, CopyText>
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
  /** Drawer rows after the section rows — a route of the site's own, say. */
  drawerExtra: { href: string; label: string }[]
  jsonLd?: object
  /** Paths, beyond `/`, the sitemap lists. */
  sitemap: string[]
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
  /** By section id. A key that names no section is refused rather than ignored. */
  bands: Record<string, ComponentType>
}
