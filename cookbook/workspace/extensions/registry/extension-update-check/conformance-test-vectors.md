
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| extension-update-001 | no-downgrade-offered, update-value-shape | Installed `acme.widget` at `1.0.0`; registry answers `2.0.0` (universal, `engines.vscode: ^1.74.0`) | Checking this extension returns an update record with identifier `"acme.widget"`, installed-version `"1.0.0"`, latest-version `"2.0.0"` |
| extension-update-002 | no-downgrade-offered | Installed `acme.widget` at `1.0.0`; registry answers `1.0.0` | Checking this extension returns no update |
| extension-update-003 | no-downgrade-offered | Installed `acme.widget` at `1.0.0`; registry answers `0.9.0` | Checking this extension returns no update |
| extension-update-004 | registry-lookup-by-manifest-fields | Installed with `publisher: "my.company"` at `1.0.0`; registry stubbed at path `/my.company/widget` answering `namespace: "my.company"`, `2.0.0` | Checking this extension returns latest-version `"2.0.0"`, and the request path ends with `/my.company/widget`, not a path split on the interior dot |
| extension-update-005 | installability-gate | Installed `acme.widget` at `1.0.0`; registry answers `2.0.0` with `engines.vscode: "^1.200.0"` (past the host's declared `1.138.0`) | Checking this extension returns no update even though `2.0.0 > 1.0.0` |
| extension-update-006 | installability-gate | Installed `acme.widget` at `1.0.0`; registry answers `2.0.0` with `targetPlatform: "darwin-arm64"` | Checking this extension returns no update |
| extension-update-007 | publisher-required | Installed with no publisher, name `"widget"` | Checking this extension throws the no-publisher error naming `"widget"` |
| extension-update-008 | versions-must-both-parse | Installed `acme.widget` at `1.0.0`; registry answers version `"nightly-build"` | Checking this extension throws the versions-not-comparable error, carrying `"1.0.0"` and `"nightly-build"` |
| extension-update-009 | per-lookup-failure-isolation, error-classification-not-published, updates-sorted-by-identifier | Checking a list of `[current@1.0.0→registry 1.0.0, stale@2.0.0→registry 3.0.0, private@0.1.0→registry unstubbed/404]` | The updates list contains only `"acme.stale"`, with latest-version `"3.0.0"`; the not-checkable list contains `"acme.private"` with reason "not published" |
| extension-update-010 | error-classification-default-unreachable | Checking a list of `[acme.widget@1.0.0]`; registry answers status `503` | The updates list is empty; the not-checkable list contains `"acme.widget"` with reason "registry unreachable" |
| extension-update-011 | error-classification-no-publisher | Checking a list of one installed extension with no publisher | The not-checkable list's reason is "no publisher" |
| extension-update-012 | error-classification-version-not-comparable | Checking a list of one installed extension with version `"nightly"`; registry answers `2.0.0` | The not-checkable list contains `"acme.widget"` with reason "versions not comparable" |
| extension-update-013 | unavailable-sorted-by-identifier | Checking a list of two installed extensions with no publisher, named `"zebra"` and `"alpha"` | The not-checkable list's identifiers are ordered `["alpha", "zebra"]` |
| extension-update-014 | updates-sorted-by-identifier, concurrent-per-extension-lookup | Checking a list of `[zebra, alpha, middle]`, each installed at `1.0.0`, each registry stub answering `2.0.0` | The updates list's identifiers are ordered `["acme.alpha", "acme.middle", "acme.zebra"]` regardless of which lookup completes first |
| extension-update-015 | empty-input-empty-report | Checking an empty list | Both the updates list and the not-checkable list are empty |

