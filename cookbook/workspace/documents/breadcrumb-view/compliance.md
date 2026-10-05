
| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

The accessibility statuses are partial because the source sets only an accessibility identifier per crumb and leaves label, dynamic-text, and contrast behavior to AppKit's own defaults (a plain `NSButton` title and `NSColor.secondaryLabelColor`) rather than defining or verifying them itself, and because no accessibility notification accompanies a strip rebuild (see Assistive technology, above). The internationalization statuses for hardcoded strings and Unicode support are passed because the source has no hardcoded user-facing strings and displays crumb titles through `NSButton`'s native Unicode-capable text handling. `rtl-layout-support` is partial rather than passed: the strip's own leading/trailing anchors and `NSStackView` layout mirror automatically for right-to-left locales, but the chevron separator is drawn with the `chevron.right` SF Symbol, which does not mirror to point left in RTL — `chevron.forward` is the symbol that does.

`separation-of-concerns` passes because `BreadcrumbView` only derives crumbs from a file URL and the project root and reports a selected crumb's directory, with the directory listing delegated to `BreadcrumbPopoverViewController`. `unit-test-coverage` is partial: `BreadcrumbViewTests.swift` covers the empty editor, crumbs relative to the root, a file outside the root and selecting a crumb, but not popover presentation or dismissal.

