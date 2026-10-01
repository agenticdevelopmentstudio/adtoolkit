# Toolkit Repo Pattern

How this repo (`agenticdevelopertoolkit`) is laid out and consumed. Capture
this pattern when starting a sibling toolkit repo — server packages, alternate
domain SDKs, anything that ships reusable libraries to a mix of first-party
and external consumers.

## What the pattern solves

Shipping reusable packages from a single repo to two audiences:

- **First-party consumers** — apps inside your org that want live edits.
  They embed the repo as a git submodule and edit library source directly. A
  web consumer picks changes up through HMR with no build step; an Apple
  consumer references the in-tree Xcode projects and its next build compiles
  them from source.
- **External consumers** — future third-party users who `npm install @org/pkg`
  (or pick up a tagged Swift release) once the packages are published. Same
  code; a dormant publish config flips on at publish time.

No build step is needed for the first-party path. No code changes are needed
to flip on the external path.

## Repo layout

The repo root holds no language-specific manifests. Each platform owns a
top-level dir under `packages/<platform>/` which is the ROOT of that
platform's native build system (its conventional manifest lives there).

```
<repo>/
├── README.md
├── AGENTS.md
├── install.sh                       # bootstrap: regenerate Xcode projects, install + build web
├── .claude/CLAUDE.md                # agent-facing repo conventions
├── docs/
├── packages/
│   ├── web/                         # pnpm workspace root (package.json, lockfile)
│   │   ├── pnpm-workspace.yaml
│   │   └── packages/
│   │       ├── chat/
│   │       ├── themes/
│   │       ├── features/            # feature packages, one level deeper
│   │       └── …
│   ├── apple/                       # agenticdevelopertoolkit.xcworkspace + one project.yml per project
│   ├── terminal/                    # pyproject.toml
│   ├── android/                     # (TBD)
│   └── windows/                     # (TBD)
└── websites/
    ├── demo/                        # local demo / QA app (served at app root)
    └── site/                        # the toolkit's reference site
```

Libraries may only depend on other `packages/<platform>/packages/*` — never on
ad-hoc paths outside their workspace.

## The Apple platform shape

`packages/apple/` is the Apple platform root. Each subdirectory is an
XcodeGen-backed Xcode project, and `agenticdevelopertoolkit.xcworkspace`
wires the ones a developer builds together:

- `AgenticDeveloperToolkit/` — the multi-platform core and UI frameworks
  (`AgenticDeveloperToolkit`, `AgenticDeveloperToolkitUI`).
- `AgenticDeveloperHubClient/` — the hub client framework.
- `AgenticToolkit/` — the macOS-first product frameworks
  (`AgenticToolkitCore`, `AgenticToolkitMacOS`, `AIPluginKit`, the Hub, HTDV,
  Markdown, Sync and Database frameworks, and the rest) with their test
  bundles. It references the two projects above by their in-repo paths.
- `AgenticToolkitApp/` — host app that embeds the toolkit frameworks.
- `AIPlugins/` — `.aiplugin` bundles that link (without embedding) the toolkit
  frameworks, so they share the host's loaded image at `dlopen` time.
- `AvatarAnimationEngine/` and `SampleApp/` — standalone projects outside the
  workspace.

Each framework is reached through exactly one project path. Two references to
the same framework from different paths make Xcode fail with "Multiple
commands produce".

**`project.yml` is the source of truth.** Edits to a generated
`project.pbxproj` are lost on the next regeneration. The repo-root
`install.sh` regenerates every project in one shot.

## The source-by-default manifest (the key trick)

Each library's `package.json` points its `main` / `types` / `exports` at
`./src/...`, with `publishConfig` mirroring the same shape against
`./dist/...`. pnpm and npm honor `publishConfig` only at publish time:

```json
{
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "exports": {
    ".": { "types": "./src/index.ts", "import": "./src/index.ts" }
  },
  "publishConfig": {
    "main": "./dist/index.js",
    "types": "./dist/index.d.ts",
    "exports": {
      ".": { "types": "./dist/index.d.ts", "import": "./dist/index.js" }
    }
  }
}
```

In-repo and submodule consumers resolve `./src/index.ts` directly. The
consuming app's bundler (Next.js's `transpilePackages`, Vite's
`optimizeDeps`, etc.) compiles the TypeScript on demand — no toolkit build
step needed.

At publish time, `publishConfig` flips the manifest to point at `./dist/...`.
Published consumers get a prebuilt tarball with no source-or-bundler coupling.

## Consumer wiring — first-party submodule path

See [`consuming-as-submodule.md`](consuming-as-submodule.md) for the full
walkthrough. In short:

1. `git submodule add <toolkit-url> vendor/<name>`
2. Add `file:` refs to the consumer's `package.json`:
   `"@org/pkg": "file:./vendor/<name>/packages/<platform>/packages/pkg"`
3. List the same names under the consuming app's transpile list
   (e.g., Next.js `transpilePackages`).
4. From the consumer app dir, run your project's install command
   (`npm install` / `pnpm install` / `yarn`).

Live edits in `vendor/<name>/packages/<platform>/packages/<pkg>/src/` flow
through to the consumer's dev server via HMR.

An Apple consumer adds `packages/apple/agenticdevelopertoolkit.xcworkspace`
(or one of its projects) to its own Xcode workspace instead, and runs
`./vendor/<name>/install.sh` after pulling a revision that changed a
`project.yml`.

## Consumer wiring — future npm path

Once the packages are published, external consumers just
`npm install @org/pkg`. `publishConfig` makes their tarball point at `dist/`,
so they don't need `transpilePackages` or any submodule setup. The first-party
submodule flow continues to work in parallel — same source, different shipping.

## The install script at the repo root

`install.sh` bootstraps the workspace for toolkit developers: it regenerates
every Apple Xcode project from its `project.yml`, runs
`pnpm install && pnpm build` in `packages/web`, and prints pointers to test /
build commands. Web consumers don't run it — they run their own project's
install command (`npm install` / `pnpm install` / `yarn`) from the consumer app
dir after pulling a new submodule SHA, and their package manager picks up the
`file:` refs and re-links them. Apple consumers run it through the submodule
path after a pull, so the generated `.xcodeproj` files match the pulled
`project.yml`.

## Deployment

Enable submodule checkout in your deploy platform:

- **Vercel:** Settings → Git → Include submodules.
- **Cloudflare Pages:** Settings → Builds & deployments → Include submodules.
- **GitHub Actions:** `actions/checkout@v4` with `submodules: recursive`.
- **Xcode Cloud:** check "Include submodules" in the workflow source settings.

The build container runs the consumer's normal install + build. The consuming
framework (Next.js, etc.) handles source-to-bundle for the toolkit packages.
No toolkit build step required in CI.

## Adapting for other ecosystems

The pattern translates to any ecosystem with file-based local deps plus a
publish-time manifest override:

| Ecosystem | Source-by-default mechanism | Publish-time mechanism |
|---|---|---|
| TypeScript / npm | `main`/`types`/`exports` → `src/`, plus `transpilePackages` in the consumer | `publishConfig` flips to `dist/` |
| Python | `pyproject.toml` with editable installs (`pip install -e ./packages/foo`) | Standard `pip install` from a published wheel |
| Go | `replace github.com/org/pkg => ./packages/pkg` in the consumer's `go.mod` | Tagged release; consumer drops the `replace` |
| Rust | `path = "../../packages/pkg"` in the consumer's `Cargo.toml` | Tagged crate publish; consumer switches to `version = "..."` |
| Swift | XcodeGen workspace + in-tree project references | Tagged release with `from:` (SPM) or framework distribution |

**The principle is the same in every ecosystem:** package metadata points at
source by default; a publish-time mechanism flips it to a prebuilt artifact
with no code changes. Demos and first-party apps live in the same repo and
consume the packages exactly the way external consumers will.

## Starting a new toolkit repo (checklist)

- [ ] Repo root has only `README.md`, `AGENTS.md`, `install.sh`,
      `.gitignore`, `docs/`, `packages/`, and optionally `websites/`.
      No language manifest at the root.
- [ ] `packages/<platform>/` for each platform you ship; each is a workspace
      root in its native package manager.
- [ ] Library manifests point at source by default with a publish-time override.
- [ ] In-repo demo / QA app under `websites/demo/` consumes the libraries
      via the same submodule pattern external consumers will use. Run
      locally with `websites/run.sh`.
- [ ] `install.sh` bootstraps the workspace for developers. Consumers run
      their own package manager's install command; no consumer-side wrapper
      script is needed.
- [ ] `docs/consuming-as-submodule.md` documents the consumer flow.
- [ ] `docs/repo-pattern.md` (this file) documents the design so the next
      sibling repo can copy it.
- [ ] `AGENTS.md` orients agents and humans landing in the repo.
- [ ] `.claude/CLAUDE.md` captures layout and conventions for AI agents.
