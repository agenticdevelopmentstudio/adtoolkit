
- **Data collected**: A scan returns each found repository's local
  filesystem `path` and its `remote` value read verbatim from
  `.git/config`'s `[remote "origin"]` `url`. A remote URL MAY embed
  credentials if the user's own git configuration does (for example a URL
  of the form `https://user:token@host/repo.git`); this component does not
  inspect, redact, or otherwise transform this value before returning it.
- **Storage**: None — this component does not persist its results; it only
  returns them to the caller of a scan.
- **Transmission**: None — this component makes no network call and
  transmits nothing.
- **Retention**: Not applicable — this component holds no results beyond
  the single scan call's return value; retention of the returned array is
  entirely the caller's responsibility.

