
| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | failed | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on: `ariaLabel`'d `RecipientInput`s, text-labeled `Button`s, and the `Dialog` primitive's built-in focus trap/restore for the passed Accessibility checks, against the default theme spacing/typography the source doesn't itself verify for the partial ones and the `animate-spin` busy indicator shown with no `prefers-reduced-motion` gating in source; the hardcoded English strings ("Send invitation", "Cancel", "Send", "Note (optional)", the aria-labels) for the failed Internationalization checks, against the `Textarea`'s unrestricted-Unicode input for the passed one; the `Textarea` note forwarded to `onSend` with no validation or trimming for the failed Security check; and the single optional note field layered on top of the caller-seeded, read-only recipient lists for the passed Privacy & Data check.

`separation-of-concerns` passes: `send-invitation-modal.tsx` composes shared primitives (`Dialog`, `RecipientInput`, `Textarea`, `UnsavedChangesAlert`, `FieldGroup`) and hands the composed payload to a caller-supplied `onSend`; it fetches and persists nothing. `unit-test-coverage` passes: `sendInvitationModal.test.tsx` covers section rendering for email-only, SMS-only, and both, Send disabled with no recipients, the payload including only populated sections, DOM order, read-only recipient chips, and the discard-confirmation flow (confirm once a note exists, Stay keeps the note, closing directly otherwise, nested dialog registration).

