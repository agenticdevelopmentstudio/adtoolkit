
- **Data collected**: the skip-patterns setting stores folder-name and
  glob-pattern strings the user has typed or accepted, which can reveal
  something about how the user organizes their home directory; the
  active-pane-highlight and pointer-follows-focus settings store two
  boolean UI preferences with no descriptive content of their own.
- **Storage**: all three values live in local storage only. The
  secure-storage flag is not set at any of the three declarations and
  defaults to `false`, so none of the three is routed to a credential
  vault (**not-secure**).
- **Transmission**: none — this file makes no network call and transmits
  nothing.
- **Retention**: each value persists until explicitly overwritten, removed,
  or the app's local storage domain is deleted; the file itself defines no
  expiry or automatic cleanup.

