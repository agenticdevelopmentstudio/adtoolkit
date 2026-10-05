
- A write failure inside `apply` rolls back every key written in it.
- Keys that are present in the request but not in the key set are skipped without error.
- An unrecognised value for a text setting (rounding mode, currency) is stored and returned as read; only numerics are clamped.

