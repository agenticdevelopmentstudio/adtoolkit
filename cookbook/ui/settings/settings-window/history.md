
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.2 | 2026-10-04 | Mike Fullerton | Inverted prohibitions (none/neither/no X MUST) restated as MUST NOT. |
| 1.3.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Resolved the minimum-contrast-ratio marker as current behavior (theme palette roles, no contrast check in SettingsWindow) with a pending Design Decision; added separation-of-concerns (passed) and unit-test-coverage (failed, no SettingsWindow tests) compliance rows. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: replaced the fabricated recipe-quality Compliance rows with real accessibility/internationalization checks and their grounded statuses, cleaned up by `compliance_fix.py`; flagged the theme-token colors this file reads with a Minimum contrast ratio open question; downgraded `updates-help-glyph-on-navigation-change` from MUST to MAY and moved its private-method coupling into Platform Notes; recorded the stale `makeSettingsPanels()` doc comment as a pending Design Decision instead of prose; reformatted Design Decisions to the bold three-line form; trimmed `tags` to five entries and populated `depends-on`/`related`; removed leftover template instruction text from Accessibility Options; resolved the WinUI cross-reference to a full domain URL; and corrected three inaccurate conformance test vectors (settings-window-011, -015, -023, -024) and the "Activation disabled" States row. |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial extraction from `SettingsWindow.swift`. |
