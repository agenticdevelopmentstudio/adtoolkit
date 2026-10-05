
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `disclosed` (open/closed) | the section | Disclosure open state + red-accent styling | Down | Component-local state, exposed to the disclosure as a controlled open/closed value |
| `open` (dialog) | the section | Dialog open state | Down | Component-local state |
| `phase` (`warn`/`confirm`) | the section | Which dialog body renders | Internal | Component-local state |
| `typed` | the type-to-confirm input | `confirmEnabled` gate | Up then down | Component-local state; compared exactly to `confirmValue` |
| `busy` | the confirm handler | Button label + dialog lock + close suppression | Down | Component-local state |
| `error` | a rejected `onConfirm` call | Inline error line + invalid-state marker on the input | Up then down | Component-local state, nullable |
| delete effect | the section | Caller `onConfirm` (performs delete + navigation) | Up | Async callback supplied by the caller |

