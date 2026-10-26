import type { ReactElement, ReactNode } from 'react'
import { siteProdUrl } from '@agentic-toolkit/adh-registry'
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
  Versus,
} from '@agenticdevelopertoolkit/landing'
import type { NavLink, TourStep } from '@agenticdevelopertoolkit/landing'
import type { LandingBlock, LandingContent, LandingTourEdge } from './content'

// What the family's two page layouts — the snap deck (`LandingDeck`) and the continuous
// flow (`LandingFlow`) — share: how a block renders, what the section index lists, and
// where a tour edge points. One copy, because a block that renders one way in a deck and
// another in a flow is the same content saying two different things.

/**
 * The id `TourStrip` renders from a literal of its own (landing/src/blocks/TourStrip.tsx).
 * Named here because the tour's index row has to link to it, and because the generator
 * refuses a section that slugs to the same string — two `id="tour"` elements in one
 * document make `#tour` resolve to whichever comes first, and the deck's own scroll target
 * is the loser.
 */
export const TOUR_SCREEN_ID = 'tour'

/** A block BODY — a Card's, a Closer's, a Faq answer's — as `<p>` elements.
 *
 *  The kit styles a body through its paragraph child: `.lp-card p` sets the colour, weight,
 *  size and line-height, `.lp-closer p` the margins and its 48ch measure, `.lp-faq details p`
 *  the padding that separates an answer from the summary it opens under. A body rendered as
 *  a bare text child inherits the page's defaults instead — valid JSX, the right words, and
 *  only the pixels wrong. */
export function prose(paragraphs: ReactNode[]): ReactElement[] {
  return paragraphs.map((text, i) => <p key={i}>{text}</p>)
}

/** One block, in the position its section puts it. */
export function renderBlock(block: LandingBlock, key: number): ReactElement {
  switch (block.kind) {
    case 'Lede':
      return <Lede key={key}>{block.children}</Lede>
    case 'Trust':
      return <Trust key={key} items={block.items} />
    case 'Cards':
      return (
        <Cards key={key} pair={block.pair} trio={block.trio} wide={block.wide}>
          {block.items.map((card, i) => (
            <Card
              key={i}
              kicker={card.kicker}
              icon={card.icon === undefined ? undefined : `/icons/${card.icon}.svg`}
              title={card.title}
            >
              {prose(card.body)}
            </Card>
          ))}
        </Cards>
      )
    case 'Points':
      return <Points key={key} entries={block.entries} ordered={block.ordered} />
    case 'Code':
      return <Code key={key} text={block.text} />
    case 'Shot':
      return (
        <Shot
          key={key}
          title={block.title}
          caption={block.caption}
          // The package renders the placeholder only when `media` is ABSENT, so an
          // unconditional `<img>` is what made it unreachable. `pendingLabel` has no default
          // by design — it is visible copy, and the kit renders no word its host did not
          // choose — so the family chooses it here, once, for all 31 decks. It says what
          // content-buildr's placeholder image says, so a deck and a help page word a missing
          // screenshot the same way.
          pendingLabel="Screenshot coming soon"
          {...(block.src === undefined
            ? {}
            : { media: <img src={`/screenshots/${block.src}.png`} alt={block.caption} /> })}
        />
      )
    case 'Table':
      return (
        <Table key={key} caption={block.caption} columns={block.columns} rows={block.rows} />
      )
    case 'StatusPill':
      return (
        <StatusPill key={key} free={block.free}>
          {block.children}
        </StatusPill>
      )
    case 'Rule':
      return <Rule key={key} steps={block.steps} />
    case 'Stats':
      return <Stats key={key} entries={block.entries} />
    case 'Versus':
      return <Versus key={key} them={block.them} us={block.us} />
    case 'Chips':
      return <Chips key={key} entries={block.entries} soon={block.soon} />
    case 'Checklist':
      return <Checklist key={key} groups={block.groups} />
    case 'Faq':
      return (
        <Faq
          key={key}
          entries={block.entries.map((entry) => ({
            question: entry.question,
            answer: prose(entry.answer),
            open: entry.open,
          }))}
        />
      )
    case 'Closer':
      return (
        <Closer key={key} title={block.title}>
          {prose(block.body)}
        </Closer>
      )
    case 'Cta':
      return (
        <Cta key={key}>
          {block.buttons.map((button, i) => (
            <Btn key={i} href={button.href} variant={button.variant}>
              {button.label}
            </Btn>
          ))}
        </Cta>
      )
    case 'Roadmap':
      return (
        <Roadmap key={key} eyebrow={block.eyebrow}>
          {block.children.map((child, i) => renderBlock(child, i))}
        </Roadmap>
      )
    default: {
      // An exhaustiveness check rather than a runtime guard: a `kind` added to
      // `LandingBlock` with no case above is a type error on this line, at the one place
      // that could silently drop a block from every site's page at once.
      const unhandled: never = block
      return unhandled
    }
  }
}

/** `(href, label)` for every screen the deck's own sections render.
 *
 *  The hero is deliberately absent: it is the top of the page, which the browser's own Home
 *  key already reaches, and a first row meaning "go back to where you started" is the one
 *  row of a table of contents that carries no information. */
export function indexRows(content: LandingContent): NavLink[] {
  return content.sections.map((section) => ({
    href: `#${section.id}`,
    label: section.eyebrow,
  }))
}

/** A tour edge as the strip's own `TourStep`.
 *
 *  The href is resolved here rather than carried in the content: a tour edge crosses
 *  origins, and only the registry knows a site's production host. Spelling it with
 *  `siteProdUrl` keeps that one table the source of hosts instead of baking a hostname into
 *  thirty-eight generated files that no longer track it. */
export function tourStep(edge: LandingTourEdge | undefined): TourStep | undefined {
  if (edge === undefined) return undefined
  return { href: siteProdUrl(edge.site, '/tour'), label: edge.label, note: edge.note }
}
