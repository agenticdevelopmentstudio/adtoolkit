
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `context` | script context | none (required) | Every operation in this component takes the target context explicitly; there is no ambient or singleton context. |
| `value` (decode operations) | script value | none (required) | The script value to decode; decoding a diagnostic, related information, a diagnostic code, a related-information array, and a tags array all take one. |
| `diagnostic` / `relatedInformation` (encode operations) | diagnostic value / related-information value | none (required) | The host value the diagnostic encoder / related-information encoder encodes back into a real script instance. |
| `maximumDecodableArrayLength` | integer | `100_000` | The ceiling the shared array-length check enforces for any array this component walks (`relatedInformation`, `tags`). Not settable per call. |
| `severity` (constructor's 3rd argument) | script number or `undefined` | `DiagnosticSeverity.Error` (`0`) when omitted | Read by `Diagnostic`'s constructor; an explicit `0` is preserved and distinguished from "omitted" via `typeof`. |
| `severity` (host-side default) | severity value | `Error` | The host-side diagnostic value's own default, mirroring the script constructor's default. |

