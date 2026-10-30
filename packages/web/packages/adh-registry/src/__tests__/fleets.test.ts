import { describe, expect, it } from 'vitest'
import {
  DIRECTORY_SITES,
  MARKETING_FLEET_SITE_IDS,
  PLACEHOLDER_FLEET_SITE_IDS,
} from '../sites/fleets'
import { FOOTER_SITES } from '../sites/registry'

describe('the marketing and placeholder fleets', () => {
  it('are both read off a populated route share', () => {
    expect(MARKETING_FLEET_SITE_IDS.length).toBeGreaterThan(0)
    expect(PLACEHOLDER_FLEET_SITE_IDS.length).toBeGreaterThan(0)
  })

  it('share no site', () => {
    const marketing = new Set(MARKETING_FLEET_SITE_IDS)
    expect(PLACEHOLDER_FLEET_SITE_IDS.filter((id) => marketing.has(id))).toEqual([])
  })
})

describe('DIRECTORY_SITES', () => {
  it('links no marketing deck and no placeholder', () => {
    const excluded = new Set([...MARKETING_FLEET_SITE_IDS, ...PLACEHOLDER_FLEET_SITE_IDS])
    expect(DIRECTORY_SITES.filter((s) => excluded.has(s.id)).map((s) => s.id)).toEqual([])
  })

  it('is FOOTER_SITES in the same order, less only those fleets', () => {
    const excluded = new Set([...MARKETING_FLEET_SITE_IDS, ...PLACEHOLDER_FLEET_SITE_IDS])
    expect(DIRECTORY_SITES.map((s) => s.id)).toEqual(
      FOOTER_SITES.filter((s) => !excluded.has(s.id)).map((s) => s.id),
    )
  })

  it('keeps the working sites', () => {
    const ids = DIRECTORY_SITES.map((s) => s.id)
    for (const id of ['hub', 'bitbag', 'research', 'shipr', 'fishlamp'] as const) {
      expect(ids).toContain(id)
    }
  })
})
