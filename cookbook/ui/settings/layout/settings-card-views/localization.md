
Title (group container) and placeholder (search field) are the only
user-facing strings in this vocabulary, and both are opaque,
caller-supplied values with no fixed key or default of their own — there
is no string-catalog entry to list. Neither is localized automatically:
title is rendered verbatim rather than resolved against a localization
table, and placeholder is set at runtime the same way, never looked up
against a localization table. Producing an already-localized string
before it reaches either parameter is the caller's responsibility.

