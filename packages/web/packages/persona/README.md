# @agentic-toolkit/persona

The single crossing point to `@agenticdevelopertoolkit/*`.

`@agenticdevelopertoolkit/*` ships four persona web packages (`avatar`, `chat`,
`themes`, `viewport`). This package re-publishes the three of them that consumers
outside the persona itself need, so that **no consumer ever names that scope
directly**.

## Why the indirection exists

The two scopes used to live in separate repos, and a site that named
`@agenticdevelopertoolkit/chat` itself resolved a different copy on disk from the
one it reached through this package — two copies of `themes/src/colorMode.tsx`'s
module-scope React context, so a provider on one and a consumer on the other never
met. Both scopes now share one pnpm workspace, so that particular split is gone.

The single crossing point stays because it is the layering: every other
`@agentic-toolkit/*` package reaches persona vocabulary through here (or through
`@agentic-toolkit/bitbag`'s re-exports), which keeps the persona toolkit out of
every other consumer's shipped graph and gives a version skew exactly one place to
appear.

## Usage

```ts
import { InlineChat, type ChatBackend } from '@agentic-toolkit/persona/chat'
import { ThemeStyle, themeIds } from '@agentic-toolkit/persona/themes'
import { ViewportShell } from '@agentic-toolkit/persona/viewport'
```

```css
@import '@agentic-toolkit/persona/css/chat/base.css';
@import '@agentic-toolkit/persona/css/chat/modes/inline.css';
```

The entries are separate on purpose: a consumer that only wants viewport
primitives does not pull chat and themes into its graph.

## A substitution that looks right and is not

- **`@agenticdevelopertoolkit/themes`** has an id set **disjoint** from the persona
  toolkit's (`old-school-terminal` exists only there). Swapping silently changes
  which themes exist and breaks every `theme` prop's type contract.

## Relationship to `@agentic-toolkit/bitbag`

bitbag is *a persona* — his voice, avatar rig and chat surface. It legitimately
names the persona scope because it renders it. This package is *infrastructure*:
the boundary itself. Consumers that want persona vocabulary without wanting
bitbag import from here, which is why `ViewportShell` lives behind this package
and not behind a re-export on a specific persona.

`<adh-tools>/sites/scripts/verify_persona_deps.py` enforces the rule from the
consuming side.
