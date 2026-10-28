import type { ReactElement } from 'react'
import { Card, Cards, Head } from '@agenticdevelopertoolkit/landing'
import type { BandTone } from '@agenticdevelopertoolkit/landing'
import { FrameBand } from './frame-band'
import type { SiteFamily } from './types'

/** The band's id, and so its anchor: `/#family`. */
export const FAMILY_ID = 'family'

/**
 * The last band of `/` on a family site: a card for every other member of the Agentic Developer
 * Hub family, each card a link to that member's site. The card's kicker is the host the link
 * goes to, so a reader sees where it leads before following it.
 *
 * `self` must name a member: a site whose id was misspelt in site.json, or dropped from the
 * shared copy, would otherwise list itself among its own family with nothing to say so.
 */
export function FamilyBand({ family, tone }: { family: SiteFamily; tone?: BandTone }): ReactElement {
  const { copy, self } = family
  if (copy.members[self] === undefined) {
    throw new Error(
      `FamilyBand: site.json family '${self}' names no member of the family copy. ` +
        `The members are: ${Object.keys(copy.members).map((id) => `'${id}'`).join(', ') || '(none)'}.`,
    )
  }
  const others = Object.entries(copy.members).filter(([id]) => id !== self)
  return (
    <FrameBand id={FAMILY_ID} tone={tone}>
      <Head eyebrow={copy.eyebrow} title={copy.title} />
      <Cards className="st-family">
        {others.map(([id, member]) => (
          <a key={id} className="st-family__link" href={member.url}>
            <Card kicker={new URL(member.url).host} title={member.name}>
              <p>{member.blurb}</p>
            </Card>
          </a>
        ))}
      </Cards>
    </FrameBand>
  )
}
