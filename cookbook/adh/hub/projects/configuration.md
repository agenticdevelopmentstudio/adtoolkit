
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspace` (list/create, most groupings) | `string \| undefined` | `undefined` | Pins the op to that workspace's owning principal; omitted falls back to the caller's ownership reach |
| `includeUntriaged` (listing a board's cards) | `boolean \| undefined` | `false` | Include cards still sitting in the triage inbox in the board's own list |
| `direction` (listing artifact links) | `"ingested" \| "produced" \| undefined` | `undefined` (both) | Narrow the link list to one side |
| `limit`/`query`/`kind` (the attachable-artifact picker) | `number \| string \| string \| undefined` | all `undefined` | Narrow the attachable picker; `limit` is per-kind |
| `workspace`/`limit` (card search) | `string \| number \| undefined` | `undefined` / server default `20` | Narrow the search reach and clamp the page size (server clamps 1–50) |
| `workspace`/`limit` (cross-board triage list) | `string \| number \| undefined` | `undefined` / server default `50` | Narrow the cross-board inbox reach and clamp the page size (server clamps 1–200) |
| `limit` (activity, keyset) | `number \| undefined` | `undefined` (no page limit, no next-before) | Page size for the newest-first activity keyset |
| `before` (activity, keyset) | `string \| undefined` | `undefined` | Opaque `"<createdAt>\|<id>"` composite cursor for the next older page |
| Poll interval (live wake) | internal constant | `60_000` (ms) | Poll cadence while a live connection is unavailable |
| Coalescing window (live wake) | internal constant | `150` (ms) | Trailing coalescing window folding a burst of wakes into one |
| Key-prefix pattern (board key validation) | pattern constant | one letter, then 1–7 more letters or digits | Client-side mirror of the backend's work-item key-prefix shape rule |
| Priority bounds (card priority, `"standard"` scale) | `number` constants | `0` / `4` | Bounds a card's priority is written and read within |

