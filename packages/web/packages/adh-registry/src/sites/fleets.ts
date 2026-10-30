import { FOOTER_SITES, type SiteDef, type SiteId } from './registry'
import { SITE_ROUTES_MARKETING } from './routes.marketing.generated'
import { SITE_ROUTES_PLACEHOLDER } from './routes.placeholder.generated'

/** The sites the adhmarketing repo serves: one product deck per feature, each a
 *  marketing page rather than a product of its own. Read off that repo's generated
 *  route share, which `gen-site-routes.py --region marketing --check` keeps equal to
 *  the repo's App Router trees, so this cannot drift from what the repo deploys.
 *
 *  Not `MARKETING_SITE_IDS`: that array names the ids whose Next app once sat
 *  under `websites/marketing/`, before the fleets split into repos, and still holds
 *  research, docs and registry. adh-tools parses it by name, so it stays as it is. */
export const MARKETING_FLEET_SITE_IDS: readonly SiteId[] = Object.keys(
  SITE_ROUTES_MARKETING,
) as SiteId[]

/** The sites the adhplaceholders repo serves: a domain held by a holding page until
 *  its product exists. Read off that repo's route share, for the reason above. */
export const PLACEHOLDER_FLEET_SITE_IDS: readonly SiteId[] = Object.keys(
  SITE_ROUTES_PLACEHOLDER,
) as SiteId[]

const NOT_IN_DIRECTORY = new Set<SiteId>([
  ...MARKETING_FLEET_SITE_IDS,
  ...PLACEHOLDER_FLEET_SITE_IDS,
])

/** The family's working sites, in display order: {@link FOOTER_SITES} without the
 *  marketing decks and the placeholders. What a landing page's footer directory
 *  links to, so a visitor who reaches the end of a page is sent to something that
 *  does what its name says. */
export const DIRECTORY_SITES: SiteDef[] = FOOTER_SITES.filter(
  (s) => !NOT_IN_DIRECTORY.has(s.id),
)
