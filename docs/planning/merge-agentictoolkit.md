# Plan: fold agentictoolkit into agenticdevelopertoolkit

Status: draft, 2026-10-01. Branch `merge-agentictoolkit`.

Goal: everything in `agenticdevelopmentstudio/agentictoolkit` (ATK) lives in
this repo (ADT) with its full history. Shared code is combined. Then every
project that consumes ATK, ADT or both consumes only ADT.

## What the survey found

- **The two trees barely overlap.** ATK has 4,708 files and ADT has 4,575.
  Only 16 paths exist in both: the root docs (`README.md`, `AGENTS.md`,
  `.claude/CLAUDE.md`, `.claude/settings.json`, `.gitignore`, `install.sh`),
  `docs/planning/planning.md`, `docs/project/description.md`,
  `.github/workflows/web-tests.yml`, and the seven pnpm workspace root files
  under `packages/web/`. Both repos already use the same per-platform layout
  (`packages/{web,apple,android,windows}`, `websites/`, `docs/`).
- **ATK depends on ADT at exactly the commit `origin/main` points to**
  (`86fb39a7`). ATK reaches ADT through its `external/agenticdevelopertoolkit`
  submodule using `link:../../../../external/…` dependencies (about 60 of
  them), `vitest.adt.ts`, `install.sh` and CI. On the Apple side,
  `AgenticToolkit/project.yml` climbs out to the superproject's ADT checkout.
  It has to: a second ADT path breaks Xcode with "Multiple commands produce".
  The merge removes the reason for all of these workarounds.
- **This repo's local `main` is stale.** It is at `e94d5e22`, has 19 commits
  that are not on `origin/main`, and is 394 commits behind it. Of the files
  those 19 commits touch, every one except `.abstractr.json` is already on
  `origin/main`, usually in a newer form. This branch was cut from that stale
  `main`.
- **ADT has a guard against exactly this content.**
  `tools/check_no_private_scope.py` runs in CI and fails on
  `@agentic-toolkit/`, `agentictoolkit`, `agenticdeveloperhub` and `[adh]`.
  ADT's README, licence (Apache-2.0) and guard all describe it as the
  product-neutral public toolkit, extracted *out of* ATK. ATK is the adh
  product layer: adh-billing, adh-admin, the bitbag persona and so on.
  Folding it in reverses that boundary (decision D1).
- **Two spec systems.** ADT has `recipes/` with `.cookr.json`. ATK has
  `cookbook/` with `cookbook.json`, and an unmerged ATK worktree branch
  `skill-based-cookbook` is still working on it.
- **History size.** ATK has about 2,205 commits and a 91 MB `.git`. Its
  largest blobs are two old 6 MB `plugins/agentictoolkit/manifest.json`
  revisions, which is acceptable without a rewrite.
- **Consumers.** About 30 active repos consume ATK, ADT or both (table in
  Phase 3). Most carry both repos, with a second ADT nested inside ATK.
  Several still point at the old `agentic-cookbook/…` org URLs.

## Approach: an unrelated-histories merge, with no path rewriting

`git merge --allow-unrelated-histories atk/main` takes ATK files in at the
same paths they already have. Alternatives considered:

| Option | Verdict |
|---|---|
| Unrelated-histories merge, same paths | **Chosen.** ATK's SHAs survive unchanged, so `git log`, `blame` and `--follow` work on every file. ATK branches still in flight (`skill-based-cookbook`) can later be `git merge`d straight into ADT. Only 16 conflicts to resolve, all by hand. |
| `git subtree add --prefix=atk/` | Rejected. It puts the whole tree under a prefix that the layout convention does not have, so every path, tier and consumer rewrite gets longer. History only follows across the prefix with `--follow`. |
| `git filter-repo` path rewrite, then merge | Rejected. It rewrites every ATK SHA, which breaks in-flight branches and every SHA cited in docs and commits. It buys nothing, because the paths do not need to move. |

Principles: *small-reversible-decisions* (until it is pushed to `main`, the
merge is one commit to drop) and *optimize-for-change* (keeping SHAs lets
in-flight ATK work still land).

## Phase 0: prerequisites

1. Rebase this branch onto `origin/main`. Carry over only `.abstractr.json`,
   which is rewritten in Phase 2 anyway. Drop the 18 superseded commits. Then
   move the main checkout's local `main` to `origin/main`. That is the user's
   checkout, so it needs explicit permission.
2. Freeze ATK. Land or park `skill-based-cookbook`. Fetch ATK `origin/main`,
   which is 2 commits ahead of the local checkout, and record the exact SHA
   being merged.
3. Settle decisions D1–D4 below.

## Phase 1: the history merge (one commit)

1. `git remote add atk git@github.com:agenticdevelopmentstudio/agentictoolkit.git`
   and `git fetch atk`.
2. `git merge --allow-unrelated-histories --no-commit atk/main`.
3. Resolve the 16 conflicts by combining both sides, never by picking one:
   - Root `README.md`, `AGENTS.md` and `.claude/CLAUDE.md` become one
     description covering both layers.
   - `.claude/settings.json`, `.gitignore`, `install.sh` and
     `.github/workflows/web-tests.yml` become a union of both.
   - `docs/planning/planning.md` and `docs/project/description.md` are
     concatenated with headed sections.
   - The seven `packages/web/` root files are resolved in Phase 2. For the
     merge commit, take ADT's versions and keep ATK's as `*.atk` scratch, so
     the commit is a pure history join.
4. Remove the `external/agenticdevelopertoolkit` submodule (`git rm`, then
   `.gitmodules` is deleted). The repo can no longer contain itself.
5. Commit the merge and push the branch.

## Phase 2: combining the shared code

Each step below is its own commit on this branch.

1. **One pnpm workspace.**
   - `pnpm-workspace.yaml` covers `./packages/*` and
     `./packages/features/*`, keeping ADT's override floors.
   - `package.json` combines the two sides: ATK's changesets and Playwright
     devDeps, the boundary `lint`, and both `test` strategies (root vitest
     plus `pnpm -r test`).
   - `tsconfig.base.json`, `vitest.config.ts`, `vitest.setup.ts` and
     `copy-css.mjs` are merged by diff.
   - Delete `vitest.adt.ts`. `adtInline`/`adtAlias` only existed to dedupe
     react across two workspaces. Callers fall back to normal workspace
     resolution.
   - Regenerate `pnpm-lock.yaml`.
2. **Repoint every ADT dependency.** A Python script,
   `tools/repoint_adt_links.py`, rewrites every
   `link:…/external/agenticdevelopertoolkit/packages/web/packages/<x>` to
   `workspace:*`. That includes bitbag's peer and dev pairs. The script also
   deletes the `//devDependencies` prose that explains the `link:`. It is
   idempotent, with a test.
3. **One Apple workspace.**
   - In `AgenticToolkit/project.yml`, `AgenticDeveloperToolkit` and
     `AgenticDeveloperHubClient` point at `../AgenticDeveloperToolkit/…` and
     `../AgenticDeveloperHubClient/…` in the repo. The climb-out comment is
     deleted.
   - `agenticdevelopertoolkit.xcworkspace` gains the `AgenticToolkit`,
     `AgenticToolkitApp` and `AIPlugins` projects.
     `AgenticToolkit.xcworkspace` is deleted.
   - Collisions between the ATK `Markdown` and ADT
     `AgenticDeveloperToolkit` modules are checked by building.
4. **Repo plumbing.**
   - `install.sh` has one bootstrap that runs xcodegen for every project
     plus pnpm. The "sync submodules, then build ADT first" step goes.
   - CI runs ATK's boundary checks and ADT's doc and site checks in one
     workflow, with no submodule build.
   - ATK's `scripts/` (boundary checks, scope rewriter) is merged into
     `tools/`, with every path updated.
5. **`.abstractr.json`.**
   - One tier map. The `vendor` tier and `shared_packages` are dropped.
   - Name clashes are resolved: two `web-themes`, two `web-workspace`, two
     `repo-meta`, and `platform-placeholders` vs `platform-stubs`.
   - Stale ATK tiers for packages that now live in ADT (`ui`, `themes`,
     `model`, `controls`, `markdown`, `search`) are re-pointed at the ADT
     tiers.
   - `abstractr check` must be clean.
6. **The neutrality boundary** (per D1): retune or retire
   `check_no_private_scope.py`, and ATK's `check_boundaries.py`, which bans
   portable packages from importing `@agentic-toolkit/adh*`.
7. **Package scope** (per D2): keep `@agentic-toolkit/*`, or run ATK's own
   `rewrite_toolkit_scope.py` to rename it everywhere.
8. **Spec systems** (per D4): fold `cookbook/` into `recipes/` with
   `.cookr.json`, or keep both side by side.
9. **Demo sites.** `websites/site` (ATK) and `websites/demo` (ADT) live side
   by side. Their `file:` refs are repointed. `check_site_deps.py` covers
   both.
10. **Verification.**
    - Web: `pnpm install --frozen-lockfile`, `pnpm build`, `pnpm test`,
      `pnpm lint`.
    - Every `tools/*_test.py` and guard passes.
    - Apple: xcodegen, then `xcodebuild` builds every scheme in the merged
      workspace.
    - `packages/terminal`: pytest.
    - `abstractr check` passes.
    - Playwright smoke runs on both demo sites at 375, 768 and 1440 px.
11. Run `/code-review` over the whole branch, then `/ship` it to ADT `main`.

## Phase 3: consumers switch to ADT only

The layout inside ATK did not move, so for every consumer the change is a
mechanical prefix swap:

- `…/external/agentictoolkit/<path>` becomes
  `…/external/agenticdevelopertoolkit/<path>`.
- `…/external/agentictoolkit/external/agenticdevelopertoolkit/<path>` also
  becomes `…/external/agenticdevelopertoolkit/<path>`.
- The `agentictoolkit` submodule is removed, ADT is bumped to the merged
  `main`, and old `agentic-cookbook/…` URLs are corrected.

All of this goes into one Python tool, `tools/migrate_consumer.py`, with
`--dry-run`. It covers `.gitmodules`, `package.json`, `project.yml`,
`next.config.*`, `tsconfig.json` `paths`, `pnpm-workspace.yaml`,
`.github/**` and `*.py` helpers. Each consumer gets a peer worktree
(`proj -C <repo> wt create adt-only --no-enter`), the tool, a build check,
and a commit.

Order (innermost submodules first, so the parents bump to migrated
children):

1. **Nested shared children:**
   - `temporal/whatsnowtoolkit` (it also globs ADT avatar packages into its
     own workspace)
   - `adh/adh-daemon`
   - `adh/websites` (the shared `websites/external` used by the 14 adh sites
     and `myagenticteams`/`bitbag`)
2. **Apple apps:**
   - stenographer, monitr, whippet, `adh/agenticdeveloperhubapp`,
     `adh/ai-processing-node`, `ads/displayr`
   - `temporal/{olyloapp,roosterapp,whatsnowapp}`
   - `tools/{secrets,dev.local}`, `fishlampdesign/zorkapp`
   - agenticdeveloperhubapp also calls
     `external/agentictoolkit/tools/apple/embed_transitive_frameworks.py`.
3. **Web sites:**
   - `adh/adhbackend` (its CI loops over both submodules)
   - `adh/automated-test-team`
   - `surgeai/contracting` (template `tsconfig` paths and the
     `materialize-fonts.mjs` import)
   - `ads/{agenticstenographer.com,agenticdevelopmentstudio,myagenticprojects}`
   - `fishlampdesign/{fishlamp,learntruefacts,zorkwebsite}`
   - `mikefullerton/mikefullerton.com`
   - `temporal/{olylowebsite,whatsnowwebsite}`
4. **Vendored copies:** `adh/websites/{statussite,buildersite}`. Point
   `tools/shared_vendor.py` at the one ADT checkout, re-vendor, and get
   `vendor-freshness.yml` green.
5. **Tooling that names both repos:** `adh/adh-tools` (`build-site.py`,
   `vercel-isolate-deps.py`, `verify_toolkit_boundary.py`,
   `add_toolkit_dep.py`, the site template and `site-ci.yml`).
6. **Dangling, fix or drop:** `adh/adh/local/{content-studio,ui-showcase}`
   link into a `frontend/websites/external` that does not exist.

Skipped as inactive: `old-paused/*`, `experimental/*`, `deprecated/*`,
`temporal/old-temporal`.

**Production:** many of these repos auto-deploy from `main`. Consumer
branches get pushed and built, but merging any of them into a deploying
branch is the user's call, repo by repo.

## Phase 4: retire ATK

Once no active consumer references it:

1. A final ATK commit replaces the README with a pointer to ADT.
2. The GitHub repo is archived, which makes it read-only and is reversible.

## Decisions

- **D1, the neutrality boundary.** ADT's guard and licence define it as
  product-free. Does the merged repo drop that (one repo, guard retired), or
  keep the boundary inside the repo (neutral packages vs the adh layer, with
  the guard scoped to the neutral side)?
- **D2, the npm scope.** Keep `@agentic-toolkit/*`, or rename it to
  `@agenticdevelopertoolkit/*`?
- **D3, ATK's fate.** Archive on GitHub after Phase 3, or something else?
- **D4, the spec systems.** Unify ATK `cookbook/` into ADT `recipes/` now, or
  co-locate both?
