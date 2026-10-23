import { describe, it, expect } from 'vitest';
import { PLACEHOLDER_URL } from '@agentic-toolkit/deploy-platform/engine';
import { siteLinks } from '../src/lib/links';

describe('siteLinks', () => {
  const site = { platform: 'railway', projectName: 'worker' };

  it('has no live link for a deploy-only monitor — the placeholder opens nothing', () => {
    expect(siteLinks(site, [{ url: PLACEHOLDER_URL, environment: 'production' }]).live).toBeNull();
  });

  it('skips the placeholder for an endpoint that has a URL', () => {
    const links = siteLinks(site, [
      { url: PLACEHOLDER_URL, environment: 'production' },
      { url: 'staging.example.test', environment: 'staging' },
    ]);
    expect(links.live).toBe('https://staging.example.test');
  });
});
