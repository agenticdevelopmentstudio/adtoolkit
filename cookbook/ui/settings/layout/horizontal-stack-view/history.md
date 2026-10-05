
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: moved private implementation identifiers (`addSubview(_:)`, `Self.pinToEdges(_:of:)`, `stackView.addArrangedSubview(view)`, the `fatalError` message) out of requirements and into Platform Notes; named the `SettingsLayout.default[.groupSpacing]` token everywhere the spacing value is mentioned instead of repeating the literal; shortened two requirement names to subject-only kebab-case; fixed the Design Decisions `**Approved**:` format; listed sibling recipes in `related`; added this Change History table; fixed test vectors to reach the private `stackView` via `view.subviews.first as? NSStackView`, made vector 008 a concrete post-init assertion, and marked vector 001 as a compile-time check; removed an unsupported claim from the WinUI 3 note; cleaned up the Compliance table to cite only checks defined in the compliance catalog |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Compliance section rewritten as linked checks against the compliance catalog |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/layout/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | Swift-only constructs in normative sections restated as platform-neutral behavior; the Apple mechanism is in Platform Notes. |
