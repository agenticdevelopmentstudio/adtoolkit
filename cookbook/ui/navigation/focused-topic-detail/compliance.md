
| Check | Status | Category |
|---|---|---|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [safe-defaults](agenticdevelopercookbook://compliance/user-safety#safe-defaults) | passed | User Safety |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [test-pyramid](agenticdevelopercookbook://compliance/best-practices#test-pyramid) | partial | Best Practices |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [deep-linking-support](agenticdevelopercookbook://compliance/platform-compliance#deep-linking-support) | passed | Platform Compliance |

The passed rows rest on `DeleteEntitySection`'s `@base-ui/react/dialog`
primitive (focus trap, Escape-to-close), its `Label htmlFor` wiring, its
`apt-*`-only token usage, and the URL-driven `{basePath}/{id}/{topic}`
routing; the partial accessibility rows reflect that the All view's filter,
toggle, and its `role="radiogroup"`/`aria-label` are not yet built and no
computed contrast or hit-size values are given; `no-hardcoded-strings` is
failed because every string in `delete-entity-section.tsx` is a plain JSX
literal with no localization call; `test-pyramid` is partial because the
recipe defines integration-level vectors (a Playwright e2e suite) but no
unit-test strategy.

Process: the repo's pre-commit gate (`check_ui.py`, typecheck, lint,
`/code-review`) runs before every commit on this surface; it is a workflow
step, not a compliance check.

Separation-of-concerns is passed: `focused-topic-detail.tsx` composes only existing blocks (`PopupMenu`, `TopicDetail`, `SectionHeader`, `ResourceCard`) and leaves the focused pane's content to the consumer, and the destructive flow lives in the separate `DeleteEntitySection` block. Unit-test-coverage is partial: `deleteEntitySection.test.tsx` and the `topicDetail*.test.tsx` files in `packages/web/packages/ui/src/__tests__` cover the delete flow and the topic-detail block it composes, but no test file imports the focused-topic-detail block itself, so the popup/All-view/card-toggle composition is untested.

