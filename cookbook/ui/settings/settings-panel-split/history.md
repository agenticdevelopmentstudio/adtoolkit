
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: reformat Design Decisions to the bold three-line form and cite the specific member behind each quoted claim; move two implicit MUSTs out of Edge Cases into a new named requirement and plain prose; add missing help-chain conformance vectors and drop the untestable main-actor compile-time vector; renumber test vector IDs sequentially; populate depends-on/related with the base class and sibling recipes; de-duplicate the `macos` tag; disambiguate the Overview's dangling class reference; remove editorializing from the WinUI 3 bullet; mark keyboard-navigable/screen-reader-support partial and point to SplitViewController's recipe; clean up Compliance rows to match the catalog |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage compliance row (failed: no SettingsPanelSplitViewController tests). |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
