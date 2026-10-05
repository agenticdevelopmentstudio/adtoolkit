
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation, extracted from the Apple `PanelView` (AppKit, macOS) source. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: reformatted frontmatter (references moved to related, depends-on populated with GroupView/PanelHeadingView); renamed requirements to subject-noun form and updated every citation; moved the ignored-frame behavior and the coder-initializer message wording into Design Decisions; removed stray MUST labels and a garbled title from Edge Cases; marked test vector 002 as compile-time and fixed vector 004's timing and vectors 017/018 to assert PanelHeadingView's public inputs instead of its private labels; reformatted Design Decisions to the bold convention and dropped a non-decision entry; trimmed Platform Notes editorializing and moved private stack/observer identifiers there; cleaned the Compliance table to catalog-valid checks with Title Case categories. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/layout/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added Compliance rows for separation-of-concerns and unit-test-coverage |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
