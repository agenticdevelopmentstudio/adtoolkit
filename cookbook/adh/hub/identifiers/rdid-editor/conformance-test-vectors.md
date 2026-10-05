
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| rdid-editor-001 | renders-associated-label | label `"Name"`, input identifier `"leaf"` | A label reading `Name` renders, associated with the input; the input's identifier is `leaf` |
| rdid-editor-002 | generates-stable-input-id | no input identifier supplied | The rendered label's association target matches the rendered input's identifier (both non-empty) |
| rdid-editor-003 | renders-static-prefix | prefix `"persona.acme."`, value `"bob"` | Static text `persona.acme.` renders before the input; the input's value is `bob`, not `persona.acme.bob` |
| rdid-editor-004 | renders-single-input-without-prefix | prefix `""`, value `"my-org"` | No prefix element renders; a single full-width input shows value `my-org` |
| rdid-editor-005 | displays-controlled-value | value `"acme-2"` | The rendered input's value is exactly `acme-2` |
| rdid-editor-006 | lowercases-input-on-change | user types `ACME` into the input | The change is reported with value `acme` |
| rdid-editor-007 | forwards-placeholder | placeholder `"my-slug"` | The rendered input has placeholder text `my-slug` |
| rdid-editor-008 | shows-hint-below-input | hint `"Lowercase, hyphens only"`, error omitted | The footnote below the input reads `Lowercase, hyphens only` |
| rdid-editor-009 | shows-error-in-place-of-hint | hint `"Lowercase, hyphens only"`, error `"Required."` | The footnote below the input reads `Required.`, not the hint text |
| rdid-editor-010 | marks-input-invalid-on-error | error `"Required."` | The rendered input is marked invalid |
| rdid-editor-011 | omits-invalid-attribute-without-error | error omitted | The rendered input carries no invalid marker at all |
| rdid-editor-012 | disables-input-when-disabled | disabled `true` | The rendered input is in its disabled state and rejects typed input |
| rdid-editor-013 | supports-native-keyboard-input | component focused via keyboard navigation | The input receives focus and accepts typed characters with no custom key interception |
| rdid-editor-014 | generates-stable-input-id | no input identifier supplied; component re-rendered with a new value | The rendered input's generated identifier is identical before and after the re-render |
| rdid-editor-015 | shows-hint-below-input, shows-error-in-place-of-hint | hint and error both omitted | No footnote element renders below the input |

