// The server barrel. Nothing exported here carries `'use client'` — `SiteChrome` and
// `SiteBitbag` do, and ship from `./client` (src/client-barrel.ts), for the reason the
// landing kit's own barrel gives: one client module re-exported here hoists its directive
// onto the whole bundle and turns every band of a site's copy into a Client Component.
// tools/check_template_directives.py asserts it on the build.
export { LandingFrame } from './landing-frame'
export { FrameBand } from './frame-band'
export { FrameFooter } from './footer'
export { FrameMark } from './frame-mark'
export { Words } from './words'
export {
  frameMetadata,
  frameViewport,
  frameRobots,
  frameSitemap,
  frameSiteUrl,
} from './frame-metadata'
export type { BandLook, CopyText, FrameCopy, FrameConfig, SlotMap } from './types'
// A site briefs bitbag through its `bitbag` slot, and a site depends on the template and never
// names bitbag itself (package.json's `//dependencies`), so the brief's type is passed on here.
export type { BitbagVoice } from '@agentic-toolkit/bitbag'
