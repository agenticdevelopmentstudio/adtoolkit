
- **claim-exact-branch-first**: `resolve` MUST prefer the repo row whose project root and non-empty branch both match, then the repo row for the same root with an empty branch.
- **claim-unassigned**: If no repo row matches, `resolve` MUST return a claim with no repo and no project (the Unassigned bucket); the time is still tracked.
- **claim-missing-project**: If the matched repo row points at a project that does not exist, the claim MUST carry the repo but no project.
- **claim-ignores-billing-flag**: `resolve` MUST NOT consider whether billing is enabled; a repo with billing off still claims the work.
- **rate-ladder**: `rateCents` MUST return the first non-null of: the repo row's rate, the any-branch row's rate for the same root (only when the repo row has a branch), the project's default rate, the global default.
- **rate-zero-is-a-rate**: A zero rate MUST be treated as a rate, not as absence.
- **rate-no-repo**: With no repo row (a hand-assigned or manual segment), `rateCents` MUST fall to the project default, then the global default.
- **shared-ladder**: The rollup MUST use `rateCents` so the claim and the rate cannot disagree.

