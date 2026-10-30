# release-macos-app

One release pipeline for every macOS app. The app keeps a `release.json` and a few hook
commands; the toolkit holds everything else. Design:
[`specs/2026-10-16-release-macos-app-design.md`](specs/2026-10-16-release-macos-app-design.md).

```
python3 external/agenticdevelopertoolkit/tools/apple/release_macos_app.py [--repo PATH] <command>
```

The `/release [--tests]` skill (mydevsetup) drives this CLI, start to finish. It prepares
(tests only with `--tests`, warnings, version and notes, the notarized build, install,
merge and a local tag), then publishes that exact build without rebuilding, verifies the
live site serves it and pushes the tag. You can run every command by hand.

**The pipeline never deploys the website.** It only probes the site.

## Distribution layout

For an app named `<App>` with releases repo `<owner>/<repo>` (in asset names, `<App>` has each run of spaces replaced by a hyphen -- `Agentic Developer Kitchen` ships `Agentic-Developer-Kitchen-<version>.pkg` -- because GitHub rewrites a space in an asset name to a dot):

| piece | where |
|---|---|
| GitHub release `v<version>` | `<owner>/<repo>`, assets `<App>-<version>.pkg` and `<App>-<version>.zip` |
| `releases.json`, `notes/<version>.md`, `appcast.xml`, `Casks/<token>.rb` | one commit on the releases repo's branch, pushed; the repo is its own Homebrew tap |
| `/downloads`, `/downloads/latest`, `/appcast.xml` | the app's website (the host of `sparkle.feed_url`), which reads the releases repo |
| source tag `release/<version>` | the app repo, on the built commit; created locally by *prepare*, pushed by *publish* after verification |

Build artifacts: `<artifacts-root>/<version>/{<App>-<v>.pkg, <App>-<v>.zip,
appcast/appcast.xml, staging/<App>.app, provenance.json}`. `<artifacts-root>` defaults to
`build/release` in the repo (gitignore it).

## CLI

`--repo` defaults to the git toplevel of the current directory, and is accepted before or
after the command. Exit codes: **0** ok, **1** failed (each failure is printed), **2** bad
invocation or bad `release.json` (every problem is listed).

| command | does |
|---|---|
| `status [--json]` | Validates `release.json` and prints: `app`, `asset_basename` (`app` with spaces hyphenated: what the pkg and zip are named after), `version`, `build`, `notes` (absolute path), `notes_exists`, `source_tag`, `source_branch`, `releases_checkout`, `latest_published` (`{version, publishedAt}` or null, asked of GitHub with `gh release view`), `latest_published_error` (null, or why GitHub could not be asked -- `latest_published` null with no error is a first release), `hooks` (`tests`, `warnings_build`, `health`: set or not), `regenerate` (whether `version.regenerate` is set), `artifacts_default`, `toolkit`. |
| `regenerate` | Runs `version.regenerate` (e.g. `xcodegen generate`) on its own, for a fresh checkout whose generated project is not committed. A no-op, exit 0, when it is not configured. |
| `bump patch\|minor [--json]` | Rewrites the marketing version (next patch, or next minor with patch 0), the build number (+1) and every `must_match` group, then runs `version.regenerate`. Prints `<version> (build <n>)`. |
| `hook tests\|health` | Runs one configured hook from the repo root, streaming its output, and passes its exit code through. A hook that is not set exits 2 with `<name> hook is not configured`; one whose command cannot be started (missing, not executable) exits 1 with `error: hooks.<name> could not run: ...`. |
| `warnings [--log-dir DIR] [--json]` | Runs `hooks.warnings_build` into a fresh DerivedData, writes its output to `DIR/warnings-build.log`, deletes the DerivedData, then holds the log to zero warnings outside the allowlist. A hook failure prints the log tail and exits 1. Without `--log-dir` the log goes next to the temp directory. |
| `build [--branch B] [--artifacts-root DIR] [--site ORIGIN] [-v]` | The notarized build: `preflight, build, check-bundle, provision, sign, notarize-app, update-zip, appcast, sparkle-verify, pkg, notarize-pkg`. Publishes nothing. |
| `install ZIP [--apps-dir DIR]` | No-sudo swap-install of the update zip: checks the layout, quits the running app, swaps the bundle in place, tells Finder to re-read the bundle (so it draws the app's icon, not the generic placeholder), reopens it. Refuses when root owns the installed bundle (a pkg install made it), printing the one-time `sudo chown` that hands it back. |
| `installed [--apps-dir DIR] [--json]` | The installed copy has this version and build, is signed with `signing.app_identity` (default `Developer ID Application`), matches the layout and is running. Then runs `hooks.health` if set. |
| `prepared [--branch B] [--artifacts-root DIR] [--json]` | Main, its release tag and the artifacts all name one commit. Read-only. |
| `publish [--branch B] [--artifacts-root DIR] [--site ORIGIN] [-v]` | Publishes what `build` left, without rebuilding. Refuses unless HEAD is the `release/<version>` tag and the artifacts' `provenance.json` names that commit. Idempotent and resumable (see below). |
| `verify [VERSION] [--version V] [--site ORIGIN] [--timeout S] [--interval S] [--artifacts-root DIR] [--json]` | Proves the live release is this build: GitHub release, `releases.json`, cask, downloads page, latest redirect, appcast, pkg and zip. Polls every `--interval` (30) seconds for up to `--timeout` (900); `--timeout 0` checks once. Exit 1 when not ready, 2 when `VERSION` was never published. `--json` lists the checks by name with `ready`. |

`--site ORIGIN` swaps the origin of the live-site probe (a staging deploy), keeping the
routes.

### `publish` states

`publish` reads the world and does only what is left: no GitHub release means *create*; a
release with matching assets that is not in `releases.json` means *commit*; listed but
unpushed means *push*; listed and pushed is `already published` and exits 0. Anything else
is a hard failure naming the repair. In the *push* state the appcast and sparkle-verify
steps are skipped.

## `release.json`

Lives at the app repo's root. Every path is relative to that root unless it starts with `~`
(the home directory) or `/`. **Unknown keys are an error**, and a missing required key is an
error: every problem is reported at once, and nothing falls back to a default silently.
A complete example is in [`examples/release-macos-app/release.json`](examples/release-macos-app/release.json).

Required keys are marked **req**.

| key | type | default | meaning |
|---|---|---|---|
| `schema` | `1` | **req** | The file format version. |
| `app.name` | string | **req** | The product name; names the bundle `<name>.app` and the artifacts. |
| `app.bundle_id` | string | **req** | The app's bundle id. Always on the pkg's must-close list, and what the cask quits and uninstalls. |
| `app.title` | string | `app.name` | The display name (the cask's `name`). |
| `version.project_yml` | path | **req** | The XcodeGen `project.yml` holding the version settings. |
| `version.marketing_setting` | string | `MARKETING_VERSION` | The setting holding the marketing version. |
| `version.build_setting` | string | `CURRENT_PROJECT_VERSION` | The setting holding the build number. |
| `version.must_match` | list | `[]` | `[{"file": path, "pattern": regex}]`. Each regex has **exactly one group**, which must equal the marketing version; the bump rewrites that group. A pattern that matches nothing is a failure. |
| `version.nested_bundles` | list of paths | `[]` | Bundle-relative paths whose `Info.plist` must carry the app's version and build. `prepared` checks them on the staged app. |
| `version.regenerate` | argv | none | Run after a bump (typically `xcodegen generate`). |
| `build.command` | argv | **req** | The app's own Release build **and** assembly (see hooks below). |
| `build.derived_data` | path | `~/Library/Developer/Xcode/DerivedData/<cask.token>-release` | The DerivedData the build and Sparkle's tools use. |
| `build.resolve` | object | **req** | `{"workspace" \| "project": path, "scheme": name}` (exactly one of workspace or project). Drives `xcodebuild -resolvePackageDependencies` so Sparkle's `generate_keys`, `sign_update` and `generate_appcast` exist under `SourcePackages/artifacts/sparkle/Sparkle/bin`. |
| `build.expect_info` | object | `{}` | `Info.plist` key to required value, checked on the assembled bundle. |
| `layout.required` | list | `[]` | Bundle-relative paths that must exist. |
| `layout.forbidden` | list | `[]` | Bundle-relative paths that must not exist. |
| `layout.required_globs` | list | `[]` | Globs that must each match at least one path. Checked before signing, and on the unpacked zip by `install`. |
| `checks` | list | `[]` | `[{"name": str, "command": argv}]`. Each runs from the repo root with `RELEASE_APP` set to the staged bundle, after the toolkit's own bundle checks and before signing. A non-zero exit stops the build; its output is the failure. |
| `signing.app_identity` | string | `Developer ID Application` | The signing identity for the app. |
| `signing.installer_identity` | string | `Developer ID Installer` | The signing identity for the pkg. |
| `signing.notary_profile` | string | **req** | The `notarytool` keychain profile. |
| `signing.entitlements` | object | **req** | Bundle-relative path (`"."` is the app, and is required) to an entitlements file. Every other nested item keeps its own entitlements. A file holding `$(AppIdentifierPrefix)` or `$(TeamIdentifierPrefix)` is signed expanded with the Developer ID team, and an item `signing.profiles` provisions also gets `com.apple.application-identifier` and `com.apple.developer.team-identifier` -- what Xcode adds at build time and a re-signature would otherwise drop. Any other `$(...)` stops the build. Rendered files go in `<artifacts>/<version>/entitlements/`. |
| `signing.profiles` | list | `[]` | `[{"bundle": rel, "env": VAR, "bundle_id": id, "required": bool}]`. Each entry is a Developer ID provisioning profile (read from the file named by environment variable `VAR`) that replaces the development one. A staged bundle embedding a profile no entry replaces stops the build. |
| `sparkle.account` | string | **req** | The Sparkle keychain account (`generate_keys --account`). |
| `sparkle.feed_url` | https URL | **req** | What installed apps poll. The bundle's `SUFeedURL` must equal it. Its origin is the site the probe and verifier use. |
| `sparkle.public_key_setting` | string | **req** | The `project.yml` setting holding `SUPublicEDKey`. It must be non-empty and equal the keychain key's public half. |
| `releases.github_repo` | `owner/repo` | **req** | The public releases repo. |
| `releases.checkout` | path | `$RELEASE_RELEASES_CHECKOUT`, else `<main checkout>/../<repo name>` | A local clone of the releases repo. Must be clean, on its branch and current at preflight. |
| `releases.branch` | string | `main` | The releases repo's branch. |
| `source.branch` | string | `main` | The app repo's release branch. |
| `source.tag_prefix` | string | `release/` | The source tag is `<prefix><version>`. |
| `site.routes` | object | `{"downloads": "/downloads", "latest": "/downloads/latest", "appcast": "/appcast.xml"}` | If set, must have exactly those three keys. |
| `notes_dir` | path | `release-notes/` in the app repo's `docs/` | Release notes live at `<notes_dir>/<version>.md`; preflight requires them. |
| `cask.token` | string | **req** | The Homebrew cask token; the cask lands at `Casks/<token>.rb`. |
| `cask.template` | path | **req** | A `string.Template` file (see below). |
| `pkg.must_close` | list of bundle ids | `[]` | Extra ids the pkg's installer must quit; `app.bundle_id` is always added. |
| `pkg.scripts` | path | none | A directory of pkg install scripts (omit for a payload-only pkg). |
| `install.apps_dir` | path | `/Applications` | Where `install` and `installed` look. |
| `hooks.tests` | argv | **req** | Runs every test suite. |
| `hooks.warnings_build` | argv | **req** | A clean Release build into `$RELEASE_WARNINGS_DERIVED_DATA`. |
| `hooks.health` | argv | none | Checks the installed app beyond the generic checks. |
| `warnings_allowlist` | path | **req** | The accepted-warnings file (see below). |
| `toolkit` | path | `external/agenticdevelopertoolkit` | Where the app pins this toolkit; reported by `status`. |
| `env_file` | path | none | `KEY=value` lines (optional `export`, quotes and `#` comments) that fill in every variable the environment does not set -- the `signing.profiles` paths, typically. A missing file sets nothing; a profile it should have named is then reported with the file in the fix. |

### Hooks

All hooks are argv lists, run from the repo root with the inherited environment.

- **`build.command`** builds Release *and* assembles the finished `<App>.app`. It also gets
  - `RELEASE_APP_DEST`: where the finished app must end up. The command creates it; its
    parent exists and the path itself does not. Exiting 0 without leaving an app there is a
    failure naming the hook.
  - `RELEASE_DERIVED_DATA`: `build.derived_data`, the tree Sparkle's tools resolve into.
  - `RELEASE_VERSION`, `RELEASE_BUILD`.

  It must build Release with the hardened runtime and keep `project.yml`'s signing, because
  the distribution signature is the toolkit's inside-out re-sign. It exits non-zero on
  failure.
- **`hooks.tests`**: the whole test run; `hook tests` passes its exit code through.
- **`hooks.warnings_build`** gets `RELEASE_WARNINGS_DERIVED_DATA`, a fresh directory the
  toolkit creates and deletes. It must build clean into it (only a clean build reports every
  warning). Its combined stdout and stderr is the log the gate reads.
- **`hooks.health`** runs after `installed` passes, and via `hook health`.
- **`checks[].command`** gets `RELEASE_APP`.

### Cask template

`cask.template` is a `string.Template`. The app's own `uninstall`, `zap` and `caveats`
stanzas live in it literally; a literal dollar sign is written `$$`. The variables are
`$version $sha256 $url $pkg $name $homepage $feed $macos $bundle_id $token`. A template that
names any other variable, or cannot be read, fails rendering. `prepare` renders it before the notarized build (with the project's `MACOSX_DEPLOYMENT_TARGET` as the OS gate, else the newest known macOS), and `publish` renders it before anything is public; either way it is an `error:` naming `cask.template`, not a traceback. `$macos` maps the app's minimum macOS major (11 to 15, 26) to Homebrew's symbol.
`$url` and `$pkg` use brew's `#{version}` interpolation, and the rendered `url` must resolve
to the pkg that `releases.json` lists. See
[`examples/release-macos-app/cask.rb.template`](examples/release-macos-app/cask.rb.template),
which uses every variable.

### Warnings allowlist

```json
{"allowed": [
  {"pattern": "Metadata extraction skipped", "reason": "toolchain noise"}
]}
```

Each `pattern` is a regular expression matched against a warning line and each needs a
`reason`: why it cannot be fixed here (the toolchain, a third-party package, a submodule this
repo does not own). Add an entry only with the owner's approval; otherwise fix the warning.
Duplicates in the log collapse to one. An entry that matched nothing is reported as unused,
never as a failure. A bad allowlist is a config error (exit 2) reported before the build
starts.

## Adopting it in an app

1. Add `release.json` (start from the example) and `release/cask.rb.template`.
2. Write `warnings_allowlist` (`{"allowed": []}` to start).
3. Write the hooks: `build.command` (build and assemble into `RELEASE_APP_DEST`),
   `hooks.tests`, `hooks.warnings_build` and, if wanted, `hooks.health`.
4. Put the Sparkle public key in `project.yml` under `sparkle.public_key_setting`, and the
   `SUFeedURL` and `LSMinimumSystemVersion` in the app's Info.plist.
5. Create the public `<app>-releases` repo on GitHub and clone it where
   `releases.checkout` points (by default beside the app's main checkout).
6. Gitignore `build/release`.
7. Run `status` until it passes, then `/release`.

## Owner prerequisites

The pipeline names a missing one at preflight with the fix; it never creates any of them.

- A `Developer ID Application` and a `Developer ID Installer` certificate in the login
  keychain.
- A notary profile: `xcrun notarytool store-credentials <profile>`.
- A Sparkle key: `generate_keys --account <account>` (from the DerivedData Sparkle bin
  directory), whose public half is in the app.
- Developer ID provisioning profiles for any `signing.profiles` entry, with each `env`
  variable naming the file.
- `gh auth login` with push access to the releases repo.
- The website deployed with the `/downloads`, `/downloads/latest` and `/appcast.xml` routes
  reading the releases repo. Deploying it is the owner's step.
