
A compact brand wordmark for marketing sites in the site family. Given a site
identifier, it renders the site's full name (resolved from the shared site
registry) with its trailing accent word rendered in the gold accent color role
and italic — the same lead/accent split used by the marketing landing hero, via
the shared title-split logic (the single source of truth for the brand split) —
over an optional identity line (the site's registry description by default).

Reuse it to brand a marketing site's sub-pages — e.g. the public research author
index at `/<userSlug>` — so they read as part of the site rather than orphan
pages, instead of hand-rolling a bespoke header. It is a pure, static
presentational element with no client-only state, styled entirely with theme
tokens, so it renders correctly whether the surrounding page is server-rendered
or client-rendered.

It belongs with the site family's own vocabulary rather than a generic shared UI
library, because it resolves the site registry: site lookup plus the shared
title-split logic turn a site identifier into this family's brand string. The
placement rule is mechanism → the generic libraries, vocabulary → the site
family's own package. (Only the hub-mark glyph inside it is registry-free, so
that one piece comes from a separate header-vocabulary module.) It ships on its
own importable entry point, importing only the pure registry, so a consumer that
needs just the wordmark is not forced to pull in the marketing landing page's
content prose alongside it.

