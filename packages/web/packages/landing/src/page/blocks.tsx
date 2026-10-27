import type { ReactElement, ReactNode } from 'react'
import { Btn } from '../blocks/Btn'
import { Card } from '../blocks/Card'
import { Cards } from '../blocks/Cards'
import { Checklist } from '../blocks/Checklist'
import { Chips } from '../blocks/Chips'
import { Closer } from '../blocks/Closer'
import { Code } from '../blocks/Code'
import { Cta } from '../blocks/Cta'
import { Faq } from '../blocks/Faq'
import { Lede } from '../blocks/Lede'
import { Points } from '../blocks/Points'
import { Roadmap } from '../blocks/Roadmap'
import { Rule } from '../blocks/Rule'
import { Shot } from '../blocks/Shot'
import { Stats } from '../blocks/Stats'
import { StatusPill } from '../blocks/StatusPill'
import { Table } from '../blocks/Table'
import { Trust } from '../blocks/Trust'
import { Versus } from '../blocks/Versus'
import type { NavLink } from '../chrome/types'
import type { LandingBlock, LandingPage } from './types'

// What every page layout — the snap deck and the continuous flow — shares: how a block
// renders and what the section index lists. One copy, because a block that renders one way
// in a deck and another in a flow is the same content saying two different things.
//
// Server components only: every block below is one, and this module sits behind the
// server-safe barrel (tools/check-directives.py asserts dist/index.js stays free of
// `'use client'`).

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
          // The kit renders the placeholder only when `media` is ABSENT, so an
          // unconditional `<img>` is what made it unreachable. `pendingLabel` has no default
          // by design — it is visible copy, and the kit renders no word its host did not
          // choose — so the page model chooses it here, once, for every page built from
          // data. It says what content-buildr's placeholder image says, so a page and a help
          // page word a missing screenshot the same way.
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

/** `(href, label)` for every screen the page's own sections render.
 *
 *  The hero is deliberately absent: it is the top of the page, which the browser's own Home
 *  key already reaches, and a first row meaning "go back to where you started" is the one
 *  row of a table of contents that carries no information. */
export function indexRows(page: LandingPage): NavLink[] {
  return page.sections.map((section) => ({
    href: `#${section.id}`,
    label: section.eyebrow,
  }))
}
