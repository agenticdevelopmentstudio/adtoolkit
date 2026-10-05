
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial recipe — extracted from the Apple `DismissibleHintView` (AppKit, macOS) source. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: moved AppKit-only mechanics (property exposure, Auto Layout pinning/autoresizing, coder/frame traps) from Behavioral Requirements to Platform Notes; renamed every requirement to subject-noun form and updated all citations; added the self-hiding-conformance requirement and test vector; rewrote the WinUI 3 bullet from TeachingTip to a binding-driven InfoBar/StackPanel with a bound (not hardcoded) button title; fixed the spacing test vector to compare against the layout token, the redundant-write vector to use an observable KVO signal, and marked the main-actor and conformance vectors as static checks; dropped the uncited HIG claim and the malformed-trap-message edge case; reformatted Design Decisions to the bolded three-line form; rebuilt Compliance with real catalog checks in Title Case categories; added full agentictoolkit:// URLs to sibling-recipe cross-references. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/layout/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added Compliance rows for separation-of-concerns and unit-test-coverage |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
</content>
