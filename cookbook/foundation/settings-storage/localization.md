
The embedded-database provider's own error type supplies two hardcoded English description strings: one describing the failed-open case with the path and the underlying error message, and one describing the failed-schema case with the underlying error message. Neither is looked up from a localization table, so every consumer sees the same English text regardless of locale. No other user-facing string originates from the given sources.

