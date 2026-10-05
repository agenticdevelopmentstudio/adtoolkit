
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage compliance row (partial: orientation test only). |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: restate five implementation-mechanics requirements (private(set), fatalError(), holdingPriority, detail-container read, parent-chain walk) as observable outcomes and move their mechanics into the AppKit Platform Notes bullet; downgrade the removePanel-on-non-member edge case from a MUST-relied-upon contract to a documented observation; add an edge case, a test vector, and Design-Decisions wording for a nil sidebarAutosaveName; add test vectors pinning the removePanel-on-non-member and stale-nested-detail-floor behaviors; tighten test vector 021 to assert holdingPriority directly instead of an unstated width change; reformat Design Decisions to the bold three-line form; split the Overview into a short description plus Owns/Delegates-to lists; move the platform-design-languages reference into related and the three composed-ingredient recipes into depends-on; trim tags to 5 and summary to ~120 characters; and reconcile the Compliance table against the catalog, dropping seven cited checks that have no corresponding category or check in the compliance catalog. |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
