
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| AlertAndDialog | agenticdevelopertoolkit://recipes/alert-and-dialog | The dialog shell, sized to a moderate maximum width, plus the discard-confirm alert | yes | modal semantics; discard-confirm copy |
| RecipientInput | agenticdevelopertoolkit://recipes/recipient-input | Per-section recipient list, configured for email recipients or phone recipients | yes | recipient kind, seeded value, read-only |

Composed shared primitives without their own recipe domains: a multiline text field
(the per-section admin note), a field-grouping/label primitive (section structure +
labels), and a button (footer Cancel/Send).

