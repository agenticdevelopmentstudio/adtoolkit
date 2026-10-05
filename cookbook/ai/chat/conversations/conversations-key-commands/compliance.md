
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because the component only declares commands;
the registry performs them and the window decides ownership.
`no-hardcoded-strings` fails because the titles are English literals with no
localization. `unit-test-coverage` is `partial`: in
`KeyCommands/KeyCommandsPanelHierarchyTests.swift`,
`testTheConversationsWindowListsItsSingleModeCommandsUnderTheMode` installs
the section with a resolver returning `nil` and checks the panel outline
(section title, the toggle command, the "Single Conversation Mode" heading and
the two selection commands in order), which covers section-identity,
toggle-shelf-command and single-mode-feature and uses the identifier
constants. No test checks default shortcuts, what each command passes to the
controller, run-time resolution, or the declined-key behavior.

