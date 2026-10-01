# Session: folding agentictoolkit into agenticdevelopertoolkit, history and all

- **Date:** 2026-10-01
- **Session:** `4c65ef9f-d313-4299-973c-82f616743453`
- **Branch:** `merge-agentictoolkit`, `docs-update-poduran`

## Orientation

The user asked for all of agentictoolkit (ATK) to move into this repo (ADT)
with its history preserved and the shared code combined, followed later by a
consumer switch-over so every project uses only ADT. They then narrowed the
session to the code move: "don't worry about the other projects yet". The
code move is done and on `main` (`86fb39a7..301356ca`), fast-forwarded with
every original SHA and merge commit intact. Consumers (Phase 3) and retiring
ATK (Phase 4) have not started. The plan and its live status are in
[`docs/planning/merge-agentictoolkit.md`](../planning/merge-agentictoolkit.md).

## Decisions

- **Unrelated-histories merge, no path rewriting** (`06f3d038`). This keeps
  ATK's SHAs, so links to ATK commits and PRs stay valid. Rewriting paths
  with `filter-repo` would have renumbered every commit.
- **Land with `--no-squash`.** The user confirmed it: squashing would erase
  the history the merge exists to keep.
- **Land by hand, with the `linear-history` ruleset briefly lifted.** The
  user directed this explicitly, after seeing that no history-preserving path
  passes the ruleset. A script disabled ruleset 19176257, pushed
  `merge-agentictoolkit:main` as a fast-forward, and re-enabled the ruleset
  in a `finally`. The ruleset was verified `active` afterwards.
- **Rename the old repo's identity in current docs; leave records alone.**
  The user said: "anything used and current updated, historical things can
  remain". So the cookbook's ~2,200 `agentictoolkit://` URIs and ~1,000
  `(agentictoolkit)` tags were renamed. Version-history rows, `archive/` and
  `docs/sessions/` were not.
- **Keep `com.agentictoolkit` as the keychain service and logger
  subsystem.** These are runtime literals; renaming the keychain service
  would orphan secrets users already have stored.
- **Keep the `@agentic-toolkit/*` scope on the adh platform packages for
  now.** Published consumers depend on it. Renaming is open decision D2.
- **Treat ADT's `domain:` IDs as logical IDs, not paths.** The IDs are
  `agenticdevelopertoolkit://ingredients/chat/...` and
  `.../recipes/chat/...`. They are expected to "not resolve" against the
  tree.

## Considered and rejected

- **`proj wt merge --no-squash` (the `/ship` path).** It always runs
  `cc-rebase-main`, which is a plain `git rebase`. That linearises merges, so
  it tried to replay all 2,204 ATK commits from ATK's root and conflicted on
  the second one. It was aborted with no loss. `cc-merge-pr` also always
  squashes. Don't use `/ship` for any merge that must keep merge commits.
- **A PR merged with a merge commit.** Blocked by the same ruleset.
- **Linearising ATK's history with `filter-repo` and replaying it.** It
  would pass the ruleset, but it gives every ATK commit a new SHA and drops
  the merge structure. The user chose lifting the ruleset instead.

## Open threads

- **Decisions D1–D4 in the plan are unanswered.** Questions are asked one at
  a time.
  - **D1 (neutrality boundary / licence) was asked twice and is still
    unanswered.** It blocks `check_license_fields`: 45 of 63 manifests
    declare no licence.
  - **D2 (npm scope) is next.** It blocks `check_no_private_scope` and
    `check_recipe_scope --root docs`.
  - **D4 (cookbook vs recipes) comes after D2.**
- **Pre-existing ATK test failures:** integrations `OAuthCallback`, adh
  `hostCascade` and adh `productionBundleGates`.
- **Not yet run on the merged tree:** terminal `pytest`, full
  `pnpm test`/`pnpm lint`, `abstractr check`, Playwright on both sites, and a
  whole-branch `/code-review`.
- **Gap in `proj`:** `--no-squash` cannot preserve merge commits. It should
  skip the rebase when `main` hasn't moved, or pass `--rebase-merges`.
- **Phase 3 (consumers) and Phase 4 (archive ATK).**

## Pointers

- **Plan and status:**
  [`docs/planning/merge-agentictoolkit.md`](../planning/merge-agentictoolkit.md)
- **Combined-repo overview:**
  [`docs/project/project-overview.md`](../project/project-overview.md)
- **Repo guards:** `tools/check_doc_links.py` and the other guards under
  `tools/`, which CI runs in `.github/workflows/web-tests.yml`.
