// The client barrel, published as `@agenticdevelopertoolkit/site-template/client`: every
// module in this package that carries `'use client'`, and nothing else. It is a separate tsup
// entry from src/index.ts so the two never share a chunk graph (see tsup.config.ts). The file
// is not called `client.ts` only because the repo's abstractr hook refuses that stem.
export { SiteChrome } from './chrome'
export { SiteBitbag } from './bitbag'
