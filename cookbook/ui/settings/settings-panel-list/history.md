
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and updated every citation; deduped Appearance against the `TopicListViewController` recipe and added it to `depends-on` along with `settings-panel-view-controller`; dropped the `macos` tag; fixed the WinUI 3 and React/Web platform notes; replaced two unobservable test vectors with an observable rebuild-counter seam and strengthened cts-panel-list-010; reformatted Design Decisions to the bold three-line form, corrected a stale `SettingsViewController` citation, and added a decision for `open` subclassing (moved out of Behavioral Requirements/test vectors); fixed the `needs-review` compliance status to `partial` |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage compliance row (failed: no PanelListViewController tests). |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
