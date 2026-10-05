
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Claude | Initial creation from source code |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: renamed three action-style requirements to subject form and split the title-change requirement into setter and restore variants; dropped bare trailing Edge Case MUST tags; reworded the AppKit title-announcement note to cite the open accessibility question instead of asserting it; moved the internal `references` URL to `related` and added `depends-on`/`related` entries for the hosted child recipes; trimmed `tags` to the 1-5 limit; bolded the Design Decisions labels; corrected the Compliance table to cite real catalog checks and changed its `needs-review` status to `partial`; removed leftover template scaffold text from Accessibility Options; unified the hosted-content naming around `FileEditorView`, moving the private wrapper's name into the AppKit Platform Note; narrowed devc-012 to the selection node and marked devc-003/devc-032 as verified by code inspection; added test vectors for an app-wide options change and a dismissed popover; and split `clearDocument()` into a Methods list while adding `paneTitle`/`onPaneTitleChange` to Configuration |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to workspace/documents/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added separation-of-concerns (passed) and unit-test-coverage (partial) compliance rows. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
