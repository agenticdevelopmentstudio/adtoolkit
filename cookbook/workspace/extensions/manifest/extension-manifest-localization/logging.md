
Not applicable: no logging call of any kind appears anywhere in this
component. Unlike the manifest's own typed decoding-failure records, no
structured record of a missing, unreadable, or malformed table is produced
or returned to the caller either — the failure is absorbed entirely inside
the localization function, with no signal of any kind that a table existed
but could not be used (see Design Decisions and the
`explicit-error-handling` row under Compliance).

