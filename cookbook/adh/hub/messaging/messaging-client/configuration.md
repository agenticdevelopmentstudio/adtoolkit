
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dataSource` (initializer parameter) | data source reference | none (required) | Backs the status/template-listing/log/send operations. |
| `logPageSize` | integer (static) | `100` | `pageSize` passed to every log-operation call; `page` is always `1`. |
| `freeformOption` | select option (static) | `value: "", title: "Freeform message"` | The "no template selected" option in the Content select. |
| `sendFailedMessage` | string (static) | `"Could not send — check the recipient and provider config."` | Fallback save-error text when a failed send's `error` field is blank. |
| channel-type values | string-backed enumeration | fallback `email` on an unparsable form value | The two channels (`email`, `sms`) a message can be sent on. |

