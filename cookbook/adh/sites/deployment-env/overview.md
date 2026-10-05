
This is a framework-free logic module that answers one question — "is this
a dev deployment?" — in the two different ways its two different audiences
need it answered. **A server-side membership check** is evaluated against
the environment variable `DEPLOYMENT_ENV` (never delivered to the browser),
and decides what a page RENDERS. **A build-time flag** is a module-level
boolean, computed once from the build-time-inlined, bundler-visible
environment variable `NEXT_PUBLIC_DEPLOYMENT_ENV`, and decides what a dev
BUILD DOES — which menu entries exist, which helper gets called. Both read
the same three-entry allowlist, `['local', 'testing', 'staging']`, but the
two cannot be merged into one function because the build-time flag also has
to stay in a shape a build tool's constant folder can reduce to a literal
at build time — routing it through the shared allowlist would leave a
runtime lookup the folder cannot see through. This module is inherently a
web-platform concern: the split, and the constant-folding constraint
driving it, exist only because certain JavaScript bundlers inline
specially-prefixed environment variables as literal text before bundling
and then eliminate dead code by recognizing only a literal comparison at
the exact call site; see Platform Notes for the mechanism's details. This
logic replaced seven places that each spelled the same allowlist out
independently, on the mistaken theory that a shared constant would defeat
that inlining behavior, and it now anchors a cross-repo drift guard: a
separate backend process keeps its own independent copy of the same
allowlist, checked against this file's literal source text by a dedicated
test. It lives in a shared, dependency-light location rather than alongside
most of its consumers, specifically so a sibling module (this domain's
SEO-metadata logic) can read it too without creating an import cycle.

