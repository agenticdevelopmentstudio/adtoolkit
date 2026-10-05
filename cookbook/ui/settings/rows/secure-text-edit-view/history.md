
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: restructure to a delta-only recipe depending on text-edit-view, pruning duplicated requirements/appearance/states/test-vectors/edge-cases/configuration/privacy/logging content to the masking-specific delta (masks-entry-with-secure-field, forecloses-subclassing); reword forecloses-subclassing platform-neutrally and move the `final`/SwiftLint detail to Platform Notes; drop the macos tag; add text-edit-view to depends-on and checkbox-view to related; reformat Design Decisions to the bold convention and move the inherited placeholder-timing/contrast-floor decisions to text-edit-view; fix the WinUI Grid column order (Auto,\*) and correct WinUI/Compose/React commit timing to end-editing/submit instead of per-keystroke; add a partial contrast-ratio compliance row with a supporting sentence; remap compliance citations to the catalog |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Added 4 conformance test vectors (inherited text-row behavior applied to the secure field) and the unit-test-coverage Compliance row. |
| 1.3.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.3.2 | 2026-10-04 | Mike Fullerton | Swift-only constructs in normative sections restated as platform-neutral behavior; the Apple mechanism is in Platform Notes. |
