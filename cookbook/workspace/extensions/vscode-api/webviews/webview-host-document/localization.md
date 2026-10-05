
| String | Text | Source |
|--------|------|--------|
| acquire-once error message | An instance of the VS Code API has already been acquired | `bootstrapScript(initialState:)` |

The string above is hardcoded English embedded directly into the generated
JavaScript, with no lookup table, ICU message, or locale parameter anywhere
in this component. This is a deliberate compatibility fact, not a gap: the
exact wording mirrors the error the real `acquireVsCodeApi()` throws, so
extensions that inspect `Error.message` continue to work unmodified; a port
to a platform with an i18n layer MUST decide, as a design choice outside
this contract, whether to keep the literal English text for that
compatibility or route it through localization.

