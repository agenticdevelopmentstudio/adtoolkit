# The library cookbook — how it is organized, and why

`cookbook/` holds one behavioral spec per component, window, service or model
this repo implements (443 specs at 2026-10-04). Each spec is addressed as
`adtoolkit://cookbook/<group>/.../<name>` and lists the code that implements it
in its **Reference Implementations** table. The legacy root `recipes/` keeps
its own `agenticdevelopertoolkit://recipes/<name>` domains.

Every spec is a **source folder** (`<name>/artifact.json` plus one `.md` per
section) with `<name>.md` compiled from it beside it. Edit `<name>.md`, then
run `cookr convert --update <path>` to fold the edit into the folder. A spec
that names a host or model as a literal value the code handles (a `claude`
CLI call, a `.claude/` directory, a model id in a test vector) records why in
`names_hosts` in its `artifact.json`. `cookbook/cookbook.json`
is the manifest: it declares the concept groups and maps each code root
(`code.roots`) onto the group its specs belong in.

## The rules

1. **Grouped by concept, general to specific.** The top-level groups run from
   the most general to the most product-specific:

   | Group | Sub-groups |
   |-------|------------|
   | `foundation` | formats, git, networking, processes |
   | `data` | services, storage, sync |
   | `ui` | containers, controls, crud, layout, navigation, settings, theme, windows |
   | `system` | permissions, system-windows |
   | `ai` | agent-sessions, chat, mcp, models, plugins, providers |
   | `workspace` | documents, extensions, files, language, logs, notes, projects, terminal |
   | `status` | dashboard, service |
   | `adh` | hub, sites |

   A spec's place is decided by what it *is*, not by where its code lives.
2. **No loose specs at the root, and no platform directories.** The project is
   platform-agnostic, so there is no `macos/` or `web/` group: the AI chat
   window is `ai/chat/...`, whichever platform implements it.
3. **Normative text is platform-neutral.** Overview, Behavioral Requirements,
   Appearance, States, Accessibility, Edge Cases, Configuration and the test
   vectors describe behavior without naming a platform's types or frameworks.
   Platform specifics (AppKit/SwiftUI/React types, actor isolation, `Sendable`,
   nib/storyboard rules, exact API calls, private member names) live in
   **Platform Notes**, with Reference Implementations, Design Decisions,
   Compliance and Change History after them. External protocols a spec
   implements (VS Code API, LSP, AppleScript, SQL) are not platform terms
   and stay in the normative text.
4. **Titles are descriptive Title Case names** ("Disclosure Card View",
   "Project Tree"), not type names, and carry no platform role words.
   Requirement IDs that named a platform construct were renamed (for example
   `main-actor-isolation` → `main-thread-confinement`) or folded into
   Platform Notes.

## Tooling that enforces it

All three of these pass on every spec:

- `cookr coverage -p . --require complete`: every component's spec is
  `complete` under cookr's completeness rules, and no spec is unmatched.
- `cookr validate -p .`: frontmatter and links, compiled docs matching their
  folders, and host neutrality.
- `cookr compile -p . --check`: every `<name>.md` is current with its folder.
- `cookr arrangement --strict` (agenticcookbook `cookr` branch, commit
  `c65f3d5`): a spec is **aligned** when it sits anywhere inside the
  `recipes` group of a code root that its first platform's Reference
  Implementations rows fall under. It is **drifted** otherwise,
  **unplaced** with no rows, and **outside** when a row is under no root.
  Before that change, arrangement compared spec paths with the code's
  directory layout, which is what produced platform directories in the
  first place.

## History

- The branch first moved the specs from the loose root `recipes/` into
  `cookbook/` and added Reference Implementations.
- It then regrouped them by concept and rewrote the normative text
  to be platform-neutral. Specs that were rewritten got a minor version bump;
  specs that were only moved got a patch bump. The rewrite ran one subagent
  at a time, in batches, to keep usage down.
- Both landed on main squashed as `52e0776b` (PR #53). The rebase merged main's
  `disclosure-card-view` 1.2.0 (title status symbol) into the neutral spec
  as 1.3.0.

## Known defects (from a `/code-review max` of the branch, 2026-09-29)

All of these were fixed on the `recipe-conformance` branch (2026-10-04).
Each item below names the commits that fixed it.

- **Prohibitions inverted.** The rewrite changed several "MUST NOT" rules
  to "Neither X … MUST", which forbids nothing. One is the rule against
  persisting a revealed secret (`adh/hub/security/authentication-client.md`).
  The others are in `security-client.md`, `organizations.md`,
  `status/service/monitor/issues.md` and
  `workspace/extensions/vscode-api.md`.
  **Fixed:** `afcaefc6` restored 7 and `bb22df0c` restored 44 more.
- **UI-thread confinement dropped in 23 specs** (`text-edit-view`,
  `settings-panel`, `tab-pane`, …) along with most of its vectors, while 17
  sibling specs keep `confines-to-ui-thread`. The intended fix is a neutral
  `confines-to-ui-thread` requirement everywhere, with the mechanism in
  Platform Notes.
  **Fixed:** `a0663d32` restored the rule in 105 specs. `f522b3fc`,
  `f4e5d88b` and `a44bff77` folded the local variants into one wording:
  `- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.`
  Any scope detail went to Platform Notes.
- **The client-only rule is inconsistent across `status/dashboard/state/`.**
  Of 13 specs, 8 lost the MUST keyword and 4 lost the bullet.
  **Fixed:** `09afc0fd` gave one `client-only` rule and vector to every
  state spec whose module opens with `"use client"`.
- **Stub requirements.** Nine are just "- **id**: See Platform Notes." with
  no behavior and no vector (`badge`, `multi-choice-filter-button`,
  `key-command-capture-field`, `floating-chooser-panel`,
  `help-content-view`).
  **Fixed:** the batch passes (`f92d8ca3`…`908e52e1`) and the batch
  verifications against the code (`6c0501a7`…`126902f5`) wrote the
  behavior out, each with a vector.
- **Swift constructs still normative** in about 12 specs the pass missed,
  such as `contribution-point`, `extension-registry`, `buckets`,
  `customers` and `invitations`.
  **Fixed:** `276385cb` and `9b63c484`. The scanner's remaining hits on
  "actor" are the domain word (the user who acted) or requirement ids.
- **Vector IDs and references.**
  - Some vector IDs were reused for different tests (`tab-pane-045`…`047`,
    `divider-view`).
  - Some prose cites deleted requirement IDs (`settings-panel.md`,
    `divider-view.md`, `extension-webview-presenting.md`,
    `vertical-stack-view.md`).
  - Shared IDs have diverging wordings: `requires-view-model-at-construction`
    and `confines-to-ui-thread`.
  **Fixed:** `126902f5` fixed the reused vector ids, and `3a75b701` and
  `263ea7d8` fixed the dangling citations. `d33c6f35` and the UI-thread
  commits above unified the shared wordings.
- **Format.**
  - 47 specs decorate Design Decision labels.
  - 11 specs add a fourth line to the decision triple.
  - 25 specs split the one-line `NEEDS REVIEW` marker across lines.
  - All of these break cookr's completeness rules.
  **Fixed:** `e70f7cab` fixed the labels and markers, `0e9d918d` fixed the
  fourth line, and `9c37b03f` fixed the em-dash requirement bullets.
  `7245b2be` made every spec match its type's section and field shape.
- **Manifest and tools.**
  - The nested `FileBrowser` and `DocumentPane` roots lack their parent's
    ignore list, so 9 files report as missing.
  - `structure.name` is not allowed by cookr's `cookbook.schema.json`.
  - Nested roots are walked twice.
  - `tools/classify_recipes.py` keys results by basename and loses 15 specs.
  **Fixed:** `e22f96d5` fixed the manifest and the inherited ignores, and
  `20f1dfa1` fixed the classifier. The double walk of nested roots is
  harmless, because cookr dedups the results.
- **Grouping.** `data/services/resource-data.md` and `query-cache.md`
  hard-code ADH keys. `workspace/notes/notes-model.md` depends on
  `adh/hub/content/markdown-store`.
  **Fixed:** `04a3602b`. The vector prefixes are now spec-named, and the
  `'adh'` namespace defaults are stated in Platform Notes as the web
  implementation's.

Pre-existing gaps, not introduced by the regroup: there were 107 `NEEDS REVIEW`
markers, 124 missing compliance citations, and about 110 blank "Initial
creation" history rows. Cookr's completeness rules now pass on every spec.
The 58 `NEEDS REVIEW` markers left are one-line notes. Each one records
behavior the source does not implement.

## Recipe conformance (2026-10-04)

The `recipe-conformance` branch made every spec complete. The work went in
this order:

1. Mechanical fixes.
2. Eleven batches, each completing one area's specs.
3. A verification of each batch against the code.
4. The defect fixes listed above.
5. Two new specs, `conversation-focus-overlay` and
   `conversations-key-commands`, for sources a mock spec had misattributed.
6. Conversion to source folders (`9673c4c1`).

Converting surfaced a cookr bug, fixed in agenticcookbook PR #68: child specs
grouped under a plain subdirectory of a parent spec's folder (for example
`vscode-api/languages/`) had dropped out of the corpus.

Main moved while the branch was open, so a follow-up landed the rest:
- the identifier rename's edits to three compiled specs were folded into
  their folders;
- a spec was added for `LegacyDirectoryMigration`
  (`foundation/legacy-directory-migration`).
