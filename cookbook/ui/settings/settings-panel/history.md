
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation, extracted from the Apple `SettingsPanelViewController` (AppKit, macOS) source. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and updated every citation; reformatted Design Decisions to the bold form; corrected the WinUI 3 hosting-size note (no `SizeToContent` in WinUI 3) and split its bullet; marked screen-reader-support and differentiate-without-color partial instead of passed; deduplicated the `.standardBounds`/`.intrinsicContentSize` rationale into Design Decisions; made spvc-001/003 compile-time checks and gave spvc-008 a concrete expected result; rewrote bare Edge Cases MUSTs as requirement citations; moved the platform-design-languages reference into `related` and added `panel-view` to `depends-on`; removed template-residue text; title-cased Compliance categories; ran the compliance-catalog cleanup. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Replaced stale spvc-NNN citations in Configuration with requirement names; added separation-of-concerns (passed) and unit-test-coverage (partial) compliance rows. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.2.3 | 2026-10-04 | Mike Fullerton | Swift-only constructs in normative sections restated as platform-neutral behavior; the Apple mechanism is in Platform Notes. |
