
- **Empty problems with a non-ok state**: The function MUST return `""`. The big indicator view renders the sublabel only when it is truthy, so the caption disappears. This logic itself does not guard this pairing.
- **Non-empty problems with a state of `"ok"`**: The problems MUST be ignored, and the clear-board line MUST be returned.
- **Zero services while ok**: state `"ok"`, `healthyCount` 0, `servicesLength` 0, no problems MUST return `"0/0 endpoints healthy · no failed builds"`. The function does not treat "monitoring nothing" as blindness. The overview tab view handles that case with its own blind-state panel, so this string does not reach the screen there.
- **`healthyCount` greater than `servicesLength`**: The function MUST take the "monitored" branch. It never prints an impossible fraction.
- **Negative, fractional or not-a-number counts**: They are interpolated with default number-to-string conversion (e.g. `"NaN endpoints monitored · no failed builds"`), and the function MUST NOT throw. Not-a-number is never equal to itself, so such inputs MUST take the "monitored" branch. The caller derives both counts from list lengths, which makes this a typed caller precondition.
- **Unknown status word**: The row MUST still be counted and rendered verbatim, so the breakdown keeps its sum-to-count guarantee.
- **Empty-string status word**: It is an unmapped word and MUST render as `<n> ` (count followed by a trailing space) in the unmapped section.
- **Status word differing only by case or whitespace**: It MUST be treated as a distinct, unmapped word (e.g. `"Down"` or `"down "`).
- **Large counts**: The count is interpolated as-is. Every value other than exactly 1 takes the plural suffix, including 0, which cannot occur because zero-count groups are skipped.
- **Concurrent access**: Not applicable. The function is stateless and synchronous, so calls cannot interleave. The sublabel-phrase table is a constant that is never written.
- **Error states and offline**: Not applicable. The function performs no I/O. A missing or stale board is handled by the overview tab view's early returns before the sublabel-building function is called.

