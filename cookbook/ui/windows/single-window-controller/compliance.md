
| Check | Status | Category |
|---|---|---|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on direct inspection of `SingleWindowController.swift`: native
`NSWindow`/`NSPanel` construction with no custom-drawn chrome
(native-controls-preference), an explicit accessibility identifier derived
from `windowID` (screen-reader-support), and no-op repeats of
`fitWindow`/`showWindow`/`ensureCurrent` when nothing has changed
(idempotent-operations).

`separation-of-concerns` is partial: frame persistence math lives in `WindowFrameManager`, lookup in `WindowRegistry` and window placement values in `WindowSpec`, but `SingleWindowController` itself still bundles window construction, restore and delegate wiring, content refit after a move, the HUD configuration and the singleton convenience in one class. `unit-test-coverage` is partial: `SingleWindowControllerTests.swift`, `SingleWindowControllerMoveRefitTests.swift`, `SingletonWindowControllerTests.swift` and `PerIDWindowControllerTests.swift` cover subclass configuration, lifecycle, centering, delegate timing, move refit and the singleton convenience, but nothing exercises the `HUDConfiguration` path (`configureAsHUD`).

