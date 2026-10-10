# Consuming the toolkit as a git submodule

For first-party consumers (e.g. `learntruefacts`), the toolkit is consumed
directly from source via a git submodule. No `pnpm build` or `dist/` step is
required — the consumer's bundler compiles the package source on demand. Apple consumers
reference the in-tree Xcode projects and rebuild them from source; see
[Apple consumers](#apple-consumers) below.

## Requirements (web packages)

The web packages (`ui`, `markdown`, `themes`, …) are plain React libraries.
They require:

- **React 19** (`react` and `react-dom` are peer dependencies).
- **TypeScript-aware bundler that compiles the packages' `src/`** — Next.js
  (`transpilePackages`) and Vite are both supported. Next.js is **not**
  required; nothing in these packages imports `next/*`. Router-aware blocks
  take a host-supplied `LinkComponent` instead.
- **Tailwind v4**, with the consumer's CSS scanning the toolkit package
  sources (see the per-bundler setup below).

## One-time setup in the consumer

Add the submodule wherever you want it to live:

```bash
git submodule add git@github.com:agenticdevelopmentstudio/adtoolkit.git vendor/adt
```

In the consumer's `package.json` (e.g. `sites/main/package.json`), add a
`file:` ref per package you want to use:

```json
{
  "dependencies": {
    "@agenticdevelopertoolkit/chat":     "file:./vendor/adt/packages/web/packages/chat",
    "@agenticdevelopertoolkit/themes":   "file:./vendor/adt/packages/web/packages/themes",
    "@agenticdevelopertoolkit/viewport": "file:./vendor/adt/packages/web/packages/viewport"
  }
}
```

Then wire the bundler.

### Next.js

In the consumer's `next.config.ts`, list the same package names under
`transpilePackages` so Next compiles their TS/TSX:

```ts
const nextConfig: NextConfig = {
  transpilePackages: [
    "@agenticdevelopertoolkit/chat",
    "@agenticdevelopertoolkit/themes",
    "@agenticdevelopertoolkit/viewport",
  ],
};
```

### Vite

Vite compiles linked TS/TSX source natively. Each package's `exports` map
points the `development` condition at `src/` and `import` at `dist/` (which
does not exist in a submodule checkout), so resolve the `development`
condition in **every** mode — including `vite build`:

```ts
// vite.config.ts
import { defineConfig, defaultClientConditions } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: { conditions: ["development", ...defaultClientConditions] },
});
```

### Tailwind (both bundlers)

Point Tailwind at the toolkit sources from your global CSS so their utility
classes are generated:

```css
@import "tailwindcss";
@source "../vendor/adt/packages/web/packages/ui/src";
@source "../vendor/adt/packages/web/packages/markdown/src";
```

### Install

Then install, from the directory that contains the consumer's
`package.json`, using your project's package manager:

```bash
npm install      # or: pnpm install / yarn
```

This creates one symlink per package in the consumer's `node_modules/`,
each pointing at the package directory inside the submodule.

## Day-to-day workflow

- **Edit toolkit source live.** Branch the submodule
  (`cd vendor/adt && git checkout -b feature`), edit any `.tsx` / `.ts` /
  `.css` inside `packages/web/packages/<name>/src/`, save. The consumer's
  dev server (`next dev` / `vite`) picks it up through HMR immediately. No reinstall, no build.
- **Commit in two places.** Commit your toolkit changes inside the submodule,
  push. Then commit the updated submodule pointer in the consumer repo.
- **Bump in other repos.** In any other consumer:
  `git submodule update --remote vendor/adt`. Source updates flow through;
  no reinstall needed unless the toolkit added a new runtime/peer dep.
- **Add a new toolkit package.** Add a `file:` line in `package.json`
  (Next.js: also add the name to `transpilePackages`), then re-run your install command
  (`npm install` / `pnpm install` / `yarn`) to symlink it.

## Deploying

Enable submodule checkout in your deploy platform:

- **Vercel:** Settings → Git → Include submodules.
- **Cloudflare Pages:** Settings → Builds & deployments → Include submodules.
- **GitHub Actions:** `actions/checkout@v4` with `submodules: recursive`.
- **Xcode Cloud:** check "Include submodules" in the workflow source settings.

The build container then runs the consumer's normal install + build (e.g.
`pnpm install && next build` or `vite build`) — the bundler handles the
source-to-bundle step. No `pnpm build` of the toolkit is required.

## Future: npm-installed consumers

External consumers (outside this org) won't use the submodule — they'll
`npm install @agenticdevelopertoolkit/chat` once the packages are published.
Each package's `publishConfig` rewrites `main`/`types`/`exports` to point at
`./dist/...` at publish time, so external consumers get a prebuilt tarball
and don't need `transpilePackages`. Until publish, `publishConfig` sits
dormant; nothing changes for the submodule flow.

To publish, from inside the toolkit repo:

```bash
cd packages/web && pnpm build         # populates dist/
pnpm --filter @agenticdevelopertoolkit/chat publish
```

## Apple consumers

The same submodule serves Apple apps. After adding it, generate the Xcode
projects once so `project.yml` and the committed `.xcodeproj` files are
confirmed in sync:

```bash
./vendor/adt/install.sh
```

In Xcode, add the toolkit workspace (or one of its projects) to your own
workspace:

- **File → Add Files to "<YourWorkspace>"…**
- Pick `vendor/adt/packages/apple/agenticdevelopertoolkit.xcworkspace` for the
  full workspace, or one of:
  - `packages/apple/AgenticDeveloperToolkit/AgenticDeveloperToolkit.xcodeproj`
  - `packages/apple/AgenticDeveloperHubClient/AgenticDeveloperHubClient.xcodeproj`
  - `packages/apple/AgenticToolkit/AgenticToolkit.xcodeproj`
  - `packages/apple/AIPlugins/AIPlugins.xcodeproj`
  - `packages/apple/AgenticToolkitApp/AgenticToolkitApp.xcodeproj`

Add each project once. `AgenticToolkit.xcodeproj` already references
`AgenticDeveloperToolkit` and `AgenticDeveloperHubClient` by their in-repo
paths, and a second reference to either from another path makes Xcode fail with
"Multiple commands produce".

Then, in your app target's **Frameworks, Libraries, and Embedded Content**
section, add the toolkit framework(s) you link against (e.g.
`AgenticToolkitMacOS.framework`).

Day to day:

- **Edit toolkit source live.** Edit any `.swift` file under
  `vendor/adt/packages/apple/`; your next Xcode build picks it up.
- **After a pull or a `project.yml` edit**, re-run `./vendor/adt/install.sh`
  so the `.xcodeproj` files match `project.yml`.
- **CI** runs the consumer's normal `xcodebuild` against its own workspace,
  which builds the toolkit projects from source. No prebuilt toolkit artifact
  is required. Unattended `xcodebuild` runs need
  `-skipPackagePluginValidation -skipMacroValidation`, because the toolkit's
  package dependencies ship build plugins and macros.

External consumers will eventually take a tagged release instead — a Swift
Package (`.package(url: ..., from: "x.y.z")`) or a distributed XCFramework.
The source layout does not change; only the consumer's package reference does.
