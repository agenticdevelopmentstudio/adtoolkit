# `@agenticdevelopertoolkit/ui`

shadcn/ui primitives, framework-agnostic. The package ships these as source — your
bundler compiles them.

## What's here

- `components/` — primitives added via `npx shadcn@latest add <name>` (run from the repo root)
- `blocks/` — larger compositions built out of those primitives
- `lib/utils.ts` — `cn()` helper (created by shadcn on first add)
- `hooks/` — shared React hooks
- `styles/globals.css` — Tailwind v4 base + shadcn `:root` / `.dark` token block
- `styles/components.css` — the semantic-class skin for the primitives that theme
  through class names rather than utilities

## Adding primitives

From the repo root:

```sh
npx shadcn@latest add button dialog input
```

shadcn writes to `packages/web/packages/ui/src/components/`. The `exports` map publishes
them automatically through its `./components/*` wildcard — no per-component edit needed.

## Using primitives in a consumer app

The same package works for both Vite and Next.js consumers. The `"use client"` directive
shadcn writes is required by Next.js App Router and is a no-op under Vite.

### Vite consumer

1. Add the dependency (`workspace:*` inside this monorepo, a `file:` dep for a submodule
   consumer).
2. Import the CSS once in your entry (e.g. `src/main.tsx`):
   ```ts
   import '@agenticdevelopertoolkit/ui/styles/globals.css'
   import '@agenticdevelopertoolkit/themes/styles/agenticdevelopmentstudioweb.css'
   ```
3. `vite.config.ts` should already include `@tailwindcss/vite` — no change.
4. Use:
   ```tsx
   import { Button } from '@agenticdevelopertoolkit/ui/components/button'
   ```

### Next.js consumer (App Router)

1. Add the dependency the same way.
2. Import the CSS once in `app/layout.tsx`:
   ```ts
   import '@agenticdevelopertoolkit/ui/styles/globals.css'
   import '@agenticdevelopertoolkit/themes/styles/agenticdevelopmentstudioweb.css'
   ```
3. Ensure your Tailwind v4 setup is wired (`@tailwindcss/postcss` in `postcss.config.mjs`).
4. Use:
   ```tsx
   import { Button } from '@agenticdevelopertoolkit/ui/components/button'
   ```

## Theming

`globals.css` defines shadcn's neutral defaults on `:root` and `.dark`. The
`@agenticdevelopertoolkit/themes` stylesheets override those CSS variables — pick a theme,
import it after `globals.css`, and the primitives retheme without forking shadcn output.
