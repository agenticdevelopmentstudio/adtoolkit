import { SITES, siteProdUrl } from '@agentic-toolkit/adh-registry'
import { describe, expect, it } from 'vitest'
import { BRAND_HREF, sitesPanelGroups } from '../identity'

describe('the "All sites" panel', () => {
  const entries = sitesPanelGroups().flatMap((g) => g.entries)
  const hrefs = new Set(entries.map((e) => e.href))

  it('links every site the family serves, delisted ones included', () => {
    for (const site of SITES.filter((s) => !s.adminOnly && s.crawlable !== false)) {
      expect(hrefs, site.id).toContain(siteProdUrl(site.id, '/'))
    }
  })

  it('links the two sites the registry has no entry for', () => {
    expect(hrefs).toContain(BRAND_HREF)
    expect(hrefs).toContain('https://myagenticprojects.com/')
  })

  it('lists each once, in the registry groups and no catch-all', () => {
    expect(new Set(entries.map((e) => e.key)).size).toBe(entries.length)
    expect(sitesPanelGroups().map((g) => g.label)).toEqual(['Hub', 'Learn', 'Plan', 'Build', 'Personas', 'Products', 'Hire'])
  })
})
