
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: move NumberFieldView<Int>'s own requirements, test vectors, edge cases, and design decisions out to the number-field-view recipe and cite it via depends-on/related, keeping only IntegerFieldView's own forwarding requirements; rewrite the wraps-number-field-view and arranges-single-child test vectors to assert observable outcomes (clamp visible on textField, label/textField frames) instead of the private wrapped view's internals; rename defaults-field-width-to-52-points to default-field-width and move the 52pt value into the requirement body; drop the redundant macos tag and backfill related with sibling recipe domains; reformat Design Decisions to the **Decision**/**Rationale**/**Approved** form and drop the now-inaccurate requirement-count decision; state NumberBox's POSIX-parsing and contradictory-bounds divergences in the WinUI 3 note and drop its "(the reason this recipe exists)" aside; remap Compliance citations to the catalog; backfill the missing 1.0.0 Change History row; fix the Accessibility section's dangling citation to the now-external fixes-field-width requirement |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage Compliance row, judged from the source and test targets. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.2.3 | 2026-10-04 | Mike Fullerton | Swift-only constructs in normative sections restated as platform-neutral behavior; the Apple mechanism is in Platform Notes. |
| 1.2.4 | 2026-10-04 | Mike Fullerton | requires-view-model-at-construction uses the one wording its sibling row specs share. |
