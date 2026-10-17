# release-macos-app — one release pipeline for every macOS app

- **Date:** 2026-10-16
- **Status:** approved design, implementing
- **Extracted from:** Stenographer's `scripts/release.py`, `release_verify.py`,
  `release_prepared.py`, `release_install.py`, `bundle_layout.py`,
  `app_processes.py`, `build_warnings.py`, and its `/prepare-release` and
  `/release` skills
- **Built on:** `tools/apple/macos_release.py` (signing, notarization, pkg,
  `releases.json`, `gh release create`)
- **First consumer:** AgenticDeveloperKitchen (adkitchen). Stenographer
  converts once adkitchen has shipped through it.

## Why

Stenographer has a release pipeline that works: two runs, never one (a
notarized `--build` from a release-preparation worktree, then a `--publish`
that rebuilds nothing and refuses unless HEAD is the tagged commit the
artifacts' provenance names), a verifier that proves the site serves exactly
that build, and two skills that drive it. About 80% of that code is generic.
The other 20% is Stenographer's names, paths, entitlements, payload and cask,
written as module constants.

adkitchen needs the same pipeline. Copying 2,000 lines of release code into a
second repo would leave two copies drifting apart. Instead, the generic part
moves into the toolkit beside `macos_release.py`. Each app keeps only a
`release.json` and a few hook commands, and one shared skill drives the
whole thing.

## Distribution model (unchanged from Stenographer)

For an app named `<App>` with releases repo `<owner>/<repo>`:

| piece | where |
|---|---|
| GitHub release `v<version>` | `<owner>/<repo>`, assets `<App>-<version>.pkg` + `<App>-<version>.zip` |
| `releases.json`, `notes/<version>.md`, `appcast.xml`, `Casks/<token>.rb` | one commit on the releases repo's branch, pushed; the repo is its own Homebrew tap |
| `/downloads`, `/downloads/latest`, `/appcast.xml` | the app's website (origin = the `SUFeedURL` host), which reads the releases repo. **Never deployed by this pipeline** |
| source tag `release/<version>` | the app repo, on the built commit; created local by *prepare*, pushed by *publish* after verification |

## Pieces

```
tools/apple/
  macos_release.py              existing — generic primitives
  release_macos_app.py          NEW — the CLI every app runs
  macos_app_release/            NEW — the pipeline, one module per concern
    config.py      release.json → frozen ReleaseConfig; ConfigError
    shell.py       Runner, subprocess runner, check(), step()/bullet(), git helpers
    versions.py    project.yml settings, must-match files, the bump
    state.py       Release (one run's derived paths + state), provenance
    profiles.py    Developer ID provisioning-profile validation + swap
    sparkle.py     Info.plist Sparkle sanity, tool resolution, appcast, signature checks
    site.py        live-site probe
    cask.py        Homebrew cask rendering (template + macOS symbol)
    layout.py      required/forbidden bundle paths
    processes.py   find + quit this user's processes inside one bundle
    build.py       the build pipeline
    publish.py     publish state machine + the publish pipeline
    verify.py      post-publish verifier
    prepared.py    "prepare landed" checker
    install.py     no-sudo swap-install from the update zip; installed-copy check
    warnings.py    zero-warnings gate with an owner allowlist
  macos_app_release_*_test.py   NEW — pytest, one file per module group
```

`release_macos_app.py` is the only entry point. Tests import the package
with `tools/apple` on `sys.path`, as `macos_release_test.py` already does.

The skill lives in mydevsetup: `source/agents/skills/release-macos-app/`. It
finds the CLI at `<app repo>/external/agenticdevelopertoolkit/tools/apple/release_macos_app.py`,
so each app runs the toolkit version it pins. A repo whose toolkit lives
elsewhere names it in `release.json` (`toolkit`, default
`external/agenticdevelopertoolkit`).

## `release.json`

Lives at the app repo's root. Every path in it is relative to that root,
unless it starts with `~` or `/`. Unknown keys are a `ConfigError`, so a typo
fails instead of being silently ignored (fail-fast). Example (adkitchen):

```json
{
  "schema": 1,
  "app": {
    "name": "AgenticDeveloperKitchen",
    "bundle_id": "com.agenticdevelopmentstudio.agenticdeveloperkitchen",
    "title": "Agentic Developer Kitchen"
  },
  "version": {
    "project_yml": "App/project.yml",
    "must_match": [],
    "nested_bundles": ["Contents/Applications/ADTerminal.app"],
    "regenerate": ["xcodegen", "generate", "--spec", "App/project.yml"]
  },
  "build": {
    "command": ["python3", "Scripts/release_build.py"],
    "derived_data": "~/Library/Developer/Xcode/DerivedData/adkitchen-release",
    "resolve": {"workspace": "AgenticDeveloperKitchen.xcworkspace", "scheme": "AgenticDeveloperKitchen"},
    "expect_info": {}
  },
  "layout": {"required": ["Contents/MacOS/AgenticDeveloperKitchen", "Contents/Info.plist"],
             "forbidden": [], "required_globs": []},
  "checks": [],
  "signing": {
    "app_identity": "Developer ID Application",
    "installer_identity": "Developer ID Installer",
    "notary_profile": "adkitchen-notary",
    "entitlements": {".": "App/Sources/Resources/App.entitlements"},
    "profiles": []
  },
  "sparkle": {
    "account": "adkitchen",
    "feed_url": "https://kitchen.agenticdevelopmentstudio.com/appcast.xml",
    "public_key_setting": "ADKITCHEN_SPARKLE_PUBLIC_KEY"
  },
  "releases": {"github_repo": "agenticdevelopmentstudio/adkitchen-releases", "branch": "main"},
  "cask": {"token": "adkitchen", "template": "release/cask.rb.template"},
  "pkg": {"must_close": [], "scripts": null},
  "hooks": {
    "tests": ["python3", "Scripts/dev.py", "test"],
    "warnings_build": ["python3", "Scripts/release_warnings_build.py"],
    "health": null
  },
  "warnings_allowlist": "release/warnings-allowlist.json"
}
```

Defaults, so a key may be left out:

| key | default |
|---|---|
| `app.title` | `app.name` |
| `version.marketing_setting` / `build_setting` | `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` |
| `version.must_match`, `nested_bundles` | `[]` |
| `version.regenerate` | none |
| `build.derived_data` | `~/Library/Developer/Xcode/DerivedData/<cask.token>-release` |
| `build.expect_info` | `{}` |
| `layout.*`, `checks` | empty |
| `signing.app_identity` / `installer_identity` | `Developer ID Application` / `Developer ID Installer` |
| `signing.profiles` | `[]` |
| `releases.checkout` | `$RELEASE_RELEASES_CHECKOUT` if set, else the sibling directory `<app repo's main checkout>/../<repo name>` |
| `releases.branch` | `main` |
| `source.branch` / `source.tag_prefix` | `main` / `release/` |
| `site.routes` | `{"downloads": "/downloads", "latest": "/downloads/latest", "appcast": "/appcast.xml"}` |
| `notes_dir` | `docs/release-notes` |
| `pkg.must_close` | `[app.bundle_id]` is always added; this lists *extra* ids |
| `pkg.scripts` | none (payload-only pkg) |
| `install.apps_dir` | `/Applications` |
| `hooks.health` | none (the generic `installed` check is the whole health check) |
| `toolkit` | `external/agenticdevelopertoolkit` |

Required: `app.name`, `app.bundle_id`, `version.project_yml`,
`build.command`, `build.resolve`, `signing.notary_profile`,
`signing.entitlements` (with at least `"."`), `sparkle.account`,
`sparkle.feed_url`, `sparkle.public_key_setting`, `releases.github_repo`,
`cask.token`, `cask.template`, `hooks.tests`, `hooks.warnings_build`,
`warnings_allowlist`.

### Field contracts

- **`version.must_match`** — `[{"file": path, "pattern": regex}]`. Each regex
  has exactly one group, which must equal `MARKETING_VERSION`. The bump
  rewrites that group. (Stenographer's `StenographerRouter.daemonVersion`
  is one entry.)
- **`version.nested_bundles`** — bundle-relative paths whose Info.plist must
  carry the same version and build as the app. `prepared` checks these on
  the staged app (Stenographer's widget).
- **`build.command`** — the app's own Release build *and* assembly. Run from
  the repo root with the inherited environment plus:
  - `RELEASE_APP_DEST`: where the finished `<App>.app` must end up. The
    command creates it; its parent exists, and the path itself does not.
  - `RELEASE_DERIVED_DATA`: `build.derived_data`, the same tree Sparkle's
    tools resolve into.
  - `RELEASE_VERSION`, `RELEASE_BUILD`.

  It must build Release with hardened runtime and keep project.yml's signing,
  because the distribution signature is the toolkit's inside-out re-sign. It
  exits non-zero on failure. Stenographer's command is a three-line wrapper
  around `install.build_release` and `install.install_app(dest=…)`, with its
  `STENOGRAPHER_RELEASE_CHANNEL` and plugin-self-install settings.
- **`build.resolve`** — `{"workspace"|"project": path, "scheme": name}`. It
  drives `xcodebuild -resolvePackageDependencies` into `build.derived_data`,
  so `generate_keys`, `sign_update` and `generate_appcast` exist under
  `SourcePackages/artifacts/sparkle/Sparkle/bin`.
- **`build.expect_info`** — Info.plist key → required value, checked on the
  assembled bundle (Stenographer: `{"AgenticReleaseChannel": "release"}`).
- **`layout`** — `required` and `forbidden` are bundle-relative paths.
  `required_globs` lists globs that must each match at least one path. It is
  checked before signing, and on the unpacked zip by `install`.
- **`checks`** — `[{"name": str, "command": [argv]}]`. Each runs from the repo
  root with `RELEASE_APP` set to the staged bundle, after the toolkit's own
  bundle checks and before signing. A non-zero exit stops the build; its
  output is the failure. This is where an app-only invariant goes.
- **`signing.entitlements`** — bundle-relative path (`"."` is the app) →
  entitlements file. Same semantics as `macos_release.sign_bundle`: every
  other nested item keeps its own entitlements.
- **`signing.profiles`** — `[{"bundle": rel, "env": VAR, "bundle_id": id,
  "required": bool}]`. Each entry is a Developer ID provisioning profile that
  replaces the development one. A staged bundle embedding a profile no entry
  replaces stops the build.
- **`sparkle.feed_url`** — what installed apps poll. The assembled bundle's
  `SUFeedURL` must equal it. Its origin is the site the live-site check and
  the verifier probe (`--site` swaps the origin, keeping the paths).
- **`sparkle.public_key_setting`** — the project.yml setting that holds
  `SUPublicEDKey`. It must be non-empty, and must equal the keychain key's
  public half.
- **`cask.template`** — a `string.Template` file. The app's own uninstall,
  zap and caveats stanzas live there literally. The variables it may use are
  `$version $sha256 $url $pkg $name $homepage $feed $macos $bundle_id $token`.
  A template that names any other variable fails rendering, so it stops the
  release before anything is public. `$url` and `$pkg` use brew's
  `#{version}` interpolation, and the rendered URL must resolve to the pkg
  that `releases.json` lists.
- **`hooks.*`** — argv lists, run from the repo root. `tests` runs every
  suite. `warnings_build` runs a **clean** Release build into
  `$RELEASE_WARNINGS_DERIVED_DATA` (a fresh directory the toolkit creates and
  deletes); its combined output is the log the warnings gate reads. `health`
  (optional) checks the installed app beyond the generic checks.

## CLI

`python3 <toolkit>/tools/apple/release_macos_app.py [--repo <path>] <command>`.
`--repo` defaults to the git toplevel of the current directory. Exit codes:
0 ok, 1 failed (each failure printed), 2 bad invocation or bad `release.json`.

| command | does | mirrors |
|---|---|---|
| `status [--json]` | Validates `release.json` and prints the resolved config summary: version, build, notes path, source tag, releases checkout, the newest published version and its `publishedAt`, and which hooks are set. The skill reads everything from here. | — |
| `bump {patch,minor} [--json]` | Rewrites `MARKETING_VERSION` (the next patch, or the next minor with patch 0), `CURRENT_PROJECT_VERSION + 1` and every `must_match` group. Then runs `version.regenerate`. Prints the new version and build. | the version-bump rule |
| `build [--branch B] [--artifacts-root DIR] [--site ORIGIN] [-v]` | The notarized build. Publishes nothing. | `release.py --build` |
| `publish [--branch B] [--site ORIGIN] [-v]` | Publishes what `build` left. Idempotent and resumable. | `release.py --publish` |
| `verify [VERSION] [--site] [--timeout] [--interval] [--json]` | Proves the live release is this build. Read-only. | `release_verify.py` |
| `prepared [--branch B] [--json]` | Main, its tag and the artifacts all name one commit. Read-only. | `release_prepared.py` |
| `install ZIP [--apps-dir DIR]` | A no-sudo swap-install of the update zip. | `release_install.py` |
| `installed [--json]` | The installed copy is this version and build, signed Developer ID, layout-correct and running. Then runs `hooks.health` if set. | generic half of `install_health.py --release` |
| `warnings [--log-dir DIR] [--json]` | Runs `hooks.warnings_build` into a fresh DerivedData, then holds its log to zero warnings outside the allowlist. | `build_warnings.py` + the clean build |
| `hook NAME` | Runs one configured hook (`tests`, `health`), streaming its output, and passes its exit code through. | — |

### `build` steps

`preflight → build → check-bundle → provision → sign → notarize-app →
update-zip → appcast → sparkle-verify → pkg → notarize-pkg`

These are Stenographer's steps, with `build`+`assemble` split as
*app-hook* + *toolkit checks*:

- **preflight**: `mr.preflight` (identities, notary profile, a version not
  yet released, a build above every published build, clean and pushed
  `--branch`, the Sparkle key, `gh` access, no existing GitHub release). Also:
  the `must_match` files agree, the public key is set, the notes exist, the
  releases checkout is clean, on its branch and current, the live site
  answers, the source tag does not exist yet, and the profiles validate.
  Every failure is reported at once.
- **build**: refuses submodule drift (never repairs it), then runs
  `build.command`.
- **check-bundle**: on the assembled app it checks the version and build,
  `expect_info`, `SUFeedURL == sparkle.feed_url`, the Sparkle config
  (`SUPublicEDKey` set; `SURequireSignedFeed` implies
  `SUVerifyUpdateBeforeExtraction`), that `LSMinimumSystemVersion` is
  present, `layout`, and then each `checks` entry.
- **provision → notarize-pkg**: unchanged from Stenographer, parameterised
  by the config. `provenance.json` is written `notarized: false` by `pkg`
  and rewritten `notarized: true` with fresh digests after `notarize-pkg`.

Artifacts: `<artifacts-root>/<version>/{<App>-<v>.pkg, <App>-<v>.zip,
appcast/appcast.xml, staging/<App>.app, provenance.json}`, with
`<artifacts-root>` defaulting to `build/release` in the repo (gitignored by
the app).

### `publish` steps

`preflight → appcast → sparkle-verify → publish`, unchanged.

- **preflight** requires HEAD to be the `release/<v>` tag's commit and the
  provenance's `source_sha`. The digests must still match, and the stapled,
  Gatekeeper and codesign checks must pass, with the app signed by
  `app_identity`.
- **`publish_state`**:
  - no GitHub release → **create**;
  - a release with matching assets but not in `releases.json` → **commit**;
  - listed but unpushed → **push**;
  - listed and pushed → `AlreadyPublished`, exit 0.

  Anything else is a hard failure that names the repair. When the state is
  **push**, the appcast and sparkle-verify steps are skipped.

## The skill — `/release-macos-app`

`disable-model-invocation: true`, so it is owner-invoked only. Typing it is
the owner's explicit trigger for **one** release of one app: the one case
where Claude runs `publish`. It never deploys the website.

```
/release-macos-app prepare [hotfix]      tested, built, installed, tagged candidate
/release-macos-app publish [hotfix] [--site ORIGIN]   prepare (unless already prepared), publish, verify, push the tag
```

The skill runs in the app repo (cwd). `MAIN` is the main checkout, taken from
`git rev-parse --path-format=absolute --git-common-dir`. Everything it needs
to know about the app comes from `status --json`.

**prepare** is Stenographer's twelve steps, made generic:

1. A clean, current main, with ≥ 20 GB free.
2. A strict `proj wt create release-preparation`.
3. `hook tests`.
4. `warnings`.
5. Fix commits, each patch-bumped with `bump patch`.
6. A review pause when code changed, then a squash.
7. The release version is always the next minor (`bump minor`).
8. The notes, plus the `chore(release): <v>` commit.
9. `build --branch release-preparation --artifacts-root $MAIN/build/release`,
   then `install`, then `installed`.
10. Merge with **`/ship -rebase -docs`**: no rebase, so the built sha
    survives; no docs fold, so no commit lands after it. Then
    HEAD == `source_sha`.
11. Tag locally, then `prepared`.
12. Report.

Hotfix skips steps 3, 4 and 6's pause.

**The `/ship -squash` fix.** Stenographer's step 10 calls
`/ship -squash -rebase -docs`. `/ship` has no `squash` token, because it
never squashes, so `cc-ship-plan` exits 2 on `-squash`. The generic skill
drops it.

**publish** is Stenographer's `/release`:

1. Already out? (`verify --timeout 0 --json`)
2. `prepare`.
3. `publish`, resuming a part-way failure only on the owner's explicit yes.
4. `verify`, then `installed`.
5. `git push origin release/<v>`.
6. Notify and report.

## Stenographer's conversion (later, not in this change)

Each Stenographer-only piece maps to:

| today | becomes |
|---|---|
| `router_version_failures` | `version.must_match` entry |
| `bundle_layout.REQUIRED/FORBIDDEN` + the `.aiplugin` rule | `layout` (`required_globs: ["Contents/PlugIns/*.aiplugin"]`) |
| `AgenticReleaseChannel == release` | `build.expect_info` |
| `install.build_release` + `install_app(dest=…)`, `ensure_metal_toolchain`, plugin self-install skip | `build.command` wrapper |
| `ENTITLEMENTS`, `HELPER_ENTITLEMENTS` | `signing.entitlements` |
| `DEVID_PROFILES` | `signing.profiles` |
| `CASK_TEMPLATE` + `DAEMON_LABEL`/`LEGACY_*` | `release/cask.rb.template` with the labels written literally |
| `LEGACY_MENUBAR_LABEL` must-close | `pkg.must_close` |
| `INSTALLER_SCRIPTS_DIR` | `pkg.scripts` |
| `RELEASES_REPO` absolute path / env | `releases.checkout` |
| `run_all_tests.py`, `smoke_test.py` | `hooks.tests` (one wrapper running both) |
| clean warnings build | `hooks.warnings_build` |
| `install_health.py --release` | `hooks.health` |

## What does not move

- Deciding **what** the app's tests, warnings build and health checks are.
  Those stay the app's hooks.
- Website deploys. The pipeline only probes the site.
- Signing secrets. Certificates, notary profiles, Sparkle keys and
  provisioning profiles stay owner prerequisites, which preflight names with
  the fix.

## Testing

Port Stenographer's `tests/test_release*.py` onto the package, using the same
injected `Runner` and `Fetch` fakes. No test touches a keychain, notary,
GitHub, the network or `/Applications`. Two fixture configs prove that
nothing is Stenographer-shaped:

- a **stenographer-like** config: a must-match file, nested bundles, two
  profile entries, required globs, `expect_info`, pkg scripts and an extra
  must-close;
- an **adkitchen-like** minimal config: nothing optional set.

Config tests cover every required key, unknown-key rejection, default
resolution, and path resolution (`~`, absolute, relative).

## Principles

- **dry**: one pipeline, and each app's facts in one file.
- **explicit-over-implicit**: `feed_url` is stated rather than parsed out of
  a plist that may hold a `$(VAR)`, and unknown config keys are an error.
- **fail-fast**: config validation, and preflight reports every failure at
  once.
- **dependency-injection**: `Runner`/`Fetch` throughout; the config is passed
  in, never read from module globals.
- **design-for-deletion**: app quirks are hooks, so removing one means
  removing a config line.
- **optimize-for-change**: Stenographer converts by writing a config, with no
  change to the pipeline.
