import type { ReactElement } from 'react'

/**
 * The hero's screenshot as a small picture under the composition, linking to the full-size
 * capture in a new tab: the reader sees there is a product to look at without the hero giving
 * the screen over to it.
 *
 * `src` is the `Shot`'s screenshot id, resolved as the kit resolves one
 * (`/screenshots/<id>.png`, landing's `renderBlock`), so the thumbnail and the page it opens
 * are the one file. The caption is the image's alt text, and so the link's name.
 */
export function HeroThumb({ src, caption }: { src: string; caption: string }): ReactElement {
  const href = `/screenshots/${src}.png`
  return (
    <a className="st-hero-thumb" href={href} target="_blank" rel="noopener">
      <img src={href} alt={caption} />
    </a>
  )
}
