import { featureTsup } from '../tsup.preset'

export default featureTsup([
  'src/index.ts',
  // The usage formatters, on their own so the admin console's usage reports read quantities the
  // same way without pulling in the panels.
  'src/usage/format.ts',
])
