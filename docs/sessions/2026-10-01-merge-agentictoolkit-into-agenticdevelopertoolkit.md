# Session: folding agentictoolkit into agenticdevelopertoolkit, then moving every consumer onto it

- **Date:** 2026-10-01
- **Session:** `4c65ef9f-d313-4299-973c-82f616743453`
- **Branch:** `merge-agentictoolkit`, `docs-update-poduran`, `turbopack-css-ascii`, `adh-dist-rebuild`, `docs-update-averse` (ADT); `adt-only` in each consumer repo

## Orientation

**Part 1: the merge.** The user asked to move all of agentictoolkit (ATK) into
this repo (ADT), keeping its history and combining the shared code. That
landed on `main` (`86fb39a7..301356ca`) as a fast-forward that kept every
original SHA and merge commit.

**Part 2: the switch-over.** The user then asked to:

1. Remove the ATK submodule from every repo under `~/Development`, not just
   `projects/`, and point those projects at ADT.
2. Make builds work now that ADT is a private GitHub repo. The user intends
   to open-source it later, after preparing it.
3. Work in a worktree in each repo and `/ship` it to that repo's `main`.
4. Run `/remember` at the end.

Parts 1 and 2 are both done.

- **Repos:** about 50 repos were migrated and shipped to their `main`.
- **Sweep:** a final sweep found no `.gitmodules` anywhere under
  `~/Development` that still names agentictoolkit.
- **Cleanup:** every orphaned `external/agentictoolkit` checkout left in a
  main checkout was removed, each only after verifying it was clean and had
  nothing unpushed.
- **Still open:** porting the 4 pending ATK branches when they land on ATK
  `main` (see Open threads).

The plan and its status are in
[`docs/planning/merge-agentictoolkit.md`](../planning/merge-agentictoolkit.md).

## Decisions

### Part 1: the merge

- **Unrelated-histories merge, no path rewriting** (`06f3d038`). This keeps
  ATK's SHAs, so links to ATK commits and PRs stay valid. Rewriting paths
  with `filter-repo` would have renumbered every commit.
- **Land with `--no-squash`.** The user confirmed it: squashing would erase
  the history the merge exists to keep.
- **Land by hand, with the `linear-history` ruleset briefly lifted.** The
  user directed this explicitly, as a one-time override.
  - A script disabled ruleset 19176257, fast-forward pushed `main`, and
    re-enabled the ruleset in a `finally`.
  - The ruleset was verified `active` afterwards.
- **Rename the old repo's identity in current docs; leave records alone.**
  The user's rule: "anything used and current updated, historical things can
  remain".
  - The same rule governed every consumer repo.
  - Current code, config and docs move to ADT.
  - `docs/sessions/`, `archive/`, dated plans and CHANGELOGs stay as written.
- **Keep the `com.agentictoolkit` IDs and the Swift module names.** These
  are product identifiers, and renaming the keychain service would orphan
  stored secrets.
  - This covers the keychain service and logger subsystem, the bundle IDs,
    and the `AgenticToolkit*` module names.
- **Keep the `@agentic-toolkit/*` npm scope for now.** Published consumers
  depend on it. Renaming it is open decision D2.

### Part 2: the switch-over

- **Migration is a prefix swap.** ATK's paths are unchanged inside ADT, so a
  script could do most of the work. Judgment covered the rest:
  - collapsing multi-workspace build logic to the one ADT workspace;
  - fixing repos where ATK and ADT sat in different parent folders;
  - reverting the script's rewrites of history docs.
- **Fan out by subagent, one `BRIEF.md` for all.** Each agent ran the same
  procedure:
  1. `proj wt create adt-only`.
  2. `migrate_consumer.py`, then the judgment half.
  3. Verify the build.
  4. Commit and push.
  5. `proj wt rebase`, `proj sub check merge`, then `proj wt merge` with a
     hand-written summary.

  The agents were barred from production branches, deployment repos and
  deploy commands.
- **Private ADT on Vercel: fetch the submodules ourselves.** Vercel cannot
  clone private submodules.
  - Every `vercel.json` `installCommand` now starts with
    `python3 <rel>/tools/fetch_submodules.py && `.
  - The script reads `GH_SUBMODULE_TOKEN`, sets a temporary global
    `insteadOf` rewrite (removed in `finally`), and does a shallow fetch with
    a full fallback.
  - Closure sites get it from adh-tools' payload; standalone repos carry a
    copy.
  - whatsnow, olylo and zork already had their own fetch wiring, which was
    kept and extended.
- **`GH_SUBMODULE_TOKEN` set centrally.** It is now on all 192 Vercel
  projects whose repo's `.gitmodules` names ADT or ATK.
  - The value was copied from an existing project (olylo.ai-testing) and
    never printed.
  - Done by a scratchpad script, `vercel_token_plan.py`.
- **GitHub Actions: org secret `ORG_REPO_READ_TOKEN`** on
  `agenticdevelopmentstudio` (visibility: all).
  - Callers of `site-ci.yml` pass it (`secrets: inherit`).
  - buildersite and statussite's `vendor-freshness.yml` check out ADT with
    it.
- **Railway needs nothing.** adhbackend's Dockerfile builds from vendored
  copies in `src/adh`.
- **adh-tools closure 3.0.0 (`fbf695c`), then 3.0.1 (`e077ac3`).**
  - 3.0.0 builds one ADT workspace and adds
    `workspace-tools/fetch_submodules.py`.
  - 3.0.1: `vercel-isolate-deps.py` now copies in same-workspace
    `peerDependencies` that `pnpm deploy` leaves out, because persona and
    bitbag take chat, avatar, viewport and gsap as peers.
  - Every closure site now reports "matches the canonical closure" against
    `e077ac3`.
- **Port ATK `main` commits into ADT as they land.**
  - `f93e604a` (dev-channel AppUpdater) was cherry-picked with `-x` onto ADT
    `main` (`bcdf96d5`).
  - `e839fa72` and `41b2bd23` only bump ATK's nested ADT, so there was
    nothing to port.
- **ADT fixes made on behalf of consumers.**
  - `d813c334`: box-drawing `─` comment rules became ASCII in the four
    stylesheets that carry `@source`. They made Turbopack panic ("end byte
    index … inside '─'") in adh's ui-showcase.
  - `48f530f3`: rebuilt `adh`'s deliberately committed `dist/`, which lagged
    its source. Only tracked files were committed; untracked dist files are
    ones no export reaches, by that package's rule.
- **Consumer pins differ, and that is fine.** Pins range from `80ed0c9d` to
  `1fabd973`, all on ADT `main`.
  - scratching-post stays at `acdc7ab` on purpose. Current ADT dropped
    `apple/Package.swift` and the SwiftUI APIs it uses, so moving it forward
    means porting the app.

## Considered and rejected

- **`proj wt merge --no-squash` for the merge (the `/ship` path).**
  - `cc-rebase-main` is a plain `git rebase`, which linearised the merge and
    conflicted replaying ATK from its root.
  - `cc-merge-pr` always squashes.
  - Don't use `/ship` for any merge that must keep merge commits.
- **A PR merged with a merge commit.** Blocked by the same ruleset.
- **Linearising ATK with `filter-repo` and replaying it.** It would have
  given every ATK commit a new SHA.
- **Rebuilding commit-graphs to fix "fatal: invalid commit position.
  commit-graph is likely corrupt".** This git bug hit rebases across
  submodule gitlink merges (whippet), and rebuilding didn't help. The
  workaround:
  1. `git rebase --abort`.
  2. `git -c core.commitGraph=false rebase origin/main`.
  3. Resolve: keep the ATK deletion and your ADT gitlink.
  4. `GIT_EDITOR=true git -c core.commitGraph=false rebase --continue`.
  5. `--force-with-lease` push.
  6. Re-run `proj wt merge`.
- **Assuming a main-branch merge triggers a production deploy.** An agent
  thought merging myagenticprojects did. In fact
  `myagenticprojects-production` builds the `production` branch of
  `myagenticprojectswebsite-deployment`. Check the Vercel project's linked
  repo and branch before concluding anything.

## Research and findings

- **`proj wt merge` and orphaned submodule folders.** Removing the
  submodule leaves an untracked orphaned `external/agentictoolkit/` folder
  in each main checkout. Folders nested in other submodules (the whatsnow
  toolkit, adh-daemon inside hubapp) also leave pointer drift. Both make the
  post-merge pull refuse with "uncommitted changes" (rc=3), even though the
  PR merged on origin.
  - **Fix:** confirm `git status --porcelain` and
    `git log --branches --not --remotes` are empty, then `rm -rf` the folder
    and drop its `submodule.*` config.
  - **Nested drift:** `git -C <sub> submodule update --recursive -- <path>`.
- **Tests that were already failing (not caused by this work):**
  - adhbackend: `customer-auth-chokepoint-unit.test.ts`, 2 failures.
  - buildersite: e2e `config-mutations.spec.ts:57` and `:92`.
  - olyloapp: `test_pin_is_current`.
  - adh-tools: `adh_config_test`, `verify_rdid_parity_test`,
    `verify_seed_sites_test`, `verify_site_identity_test`.
  - adh: `check_ui.py` and `review.py` can't find `repo_paths.py` (in adh's `tools/`).
  - hubapp: the signed iOS build fails because the
    `EmbedTransitiveFrameworks` step assumes the macOS bundle layout.
  - The ATK failures: `OAuthCallback`, `hostCascade`,
    `productionBundleGates`.

## Open threads

- **Four ATK branches to port when they land on ATK `main`:**
  - `stenographer/window-fixes`: `WindowManager.register`.
  - `adhbackend/chat`: adh-admin cost and usage panes.
  - `skill-based-cookbook`: a generated rule-skill plugin, about 2,100
    files.
  - `contracting/task1.1`: no commits yet.

  A scratchpad watcher (`watch_atk.py`, base `41b2bd23`) polls ATK `main`.
  Port each landed commit into an ADT worktree and ship it to ADT `main`.
- **Production and staging aren't on the new install command yet.** They
  build from `DeploymentRepos`, which pick up the `fetch_submodules.py`
  `installCommand` only on the user's next production ship. Shipping to
  production is the user's alone.
- **Public link to a private repo.** agenticdevelopmentstudio.com's
  `work.tsx` links to the now-private ADT repo, so public visitors get a 404
  until it is open-sourced.
- **GitHub Actions hasn't run** on buildersite or statussite since early
  September, so `vendor-freshness.yml` has passed locally only.
- **surgeai/contracting has no origin URL.** Its migration is merged on
  local `main` only.
- **Decisions D1–D4 in the plan are unanswered.**
  - **D1 (neutrality boundary and licence)** blocks `check_license_fields`.
  - **D2 (npm scope)** blocks `check_no_private_scope` and
    `check_recipe_scope`.
  - **D4 (cookbook vs recipes).**
- **Not yet run on the merged ADT tree:** terminal `pytest`, full
  `pnpm test`/`lint`, `abstractr check`, Playwright, and a whole-branch
  `/code-review`.
- **Gap in `proj`:** `--no-squash` cannot preserve merge commits.
- **Phase 4: retire the ATK repo**, once the four branches are ported.

## Pointers

- **Plan and status:**
  [`docs/planning/merge-agentictoolkit.md`](../planning/merge-agentictoolkit.md)
- **Combined-repo overview:**
  [`docs/project/project-overview.md`](../project/project-overview.md)
- **Migration tooling (session scratchpad, not committed):**
  - `BRIEF.md` and `CLOSURE_SITES.md`: the per-repo procedure.
  - `migrate_consumer.py` and `inventory.py`.
  - `fetch_submodules.py`: also canonical in adh-tools
    `workspace-tools/`.
  - `vercel_token_plan.py`.
  - `watch_atk.py`.
  - `summaries/`: one squash summary per repo.
- **adh-tools:** closure `fbf695c` (PR #19) and `e077ac3` (PR #20).
- **ADT commits from this session:**
  - `bcdf96d5`: ATK `f93e604a` ported.
  - `d813c334`: Turbopack-safe CSS comments.
  - `48f530f3`: rebuilt `adh/dist`.
