import type { Metadata } from 'next'
import type { ReactElement } from 'react'
import { FlowHero } from '@agenticdevelopertoolkit/landing'
import type { FrameCopy } from './types'
import { Words } from './words'

/** What Next's built-in 404 page says, for a site whose copy words no 404 of its own. */
const NEXT_404 = {
  title: '404: This page could not be found.',
  headline: '404',
  sub: 'This page could not be found.',
} as const

/**
 * The 404's title. A site that words its 404 (`copy.notFound`) gets its own title; one that does
 * not gets the words Next's built-in 404 page gives its tab, so it reads the same as before.
 * Either way a plain title, not a template, so it replaces the site's title rather than joining
 * it, as Next's does.
 */
export function frameNotFoundMetadata(copy: FrameCopy): Metadata {
  return { title: copy.notFound?.title ?? NEXT_404.title }
}

/**
 * The 404's screen: the window-tall hero frame, saying so. In the copy's words when it words a
 * 404 — the status code as a caption above the heading, the body under it, and a way back to
 * `/` — and otherwise in Next's.
 *
 * The way back is a plain anchor rather than a client-side `Link`: a full document load lands on
 * `/` exactly as a fresh visit does, which is the only arrival the landing page is written for.
 */
export function FrameNotFound({ copy }: { copy: FrameCopy }): ReactElement {
  const words = copy.notFound
  if (words === undefined) {
    return <FlowHero id="top" fill headline={NEXT_404.headline} sub={NEXT_404.sub} />
  }
  return (
    <FlowHero
      id="top"
      fill
      mark={<p className="st-404-code">{words.code}</p>}
      headline={words.heading}
      sub={<Words text={words.body} />}
    >
      <a className="st-404-back" href="/">
        {words.back}
      </a>
    </FlowHero>
  )
}
