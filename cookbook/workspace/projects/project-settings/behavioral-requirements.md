
- **skip-patterns-key**: the skip-patterns setting's name MUST equal the
  string `"projectScanSkipPatterns"`.
- **skip-patterns-default**: the skip-patterns setting's default value
  MUST equal the scanner's own default root skip-pattern list — the
  literal array `["Library", "Music", "Pictures", "Movies", "Dropbox",
  "* Dropbox", "Google Drive"]`.
- **highlight-active-pane-key**: the active-pane-highlight setting's name
  MUST equal the string `"highlight_active_pane"`.
- **highlight-active-pane-default**: the active-pane-highlight setting's
  default value MUST equal `true`.
- **follows-mouse-key**: the pointer-follows-focus setting's name MUST
  equal the string `"active_pane_follows_mouse"`.
- **follows-mouse-default**: the pointer-follows-focus setting's default
  value MUST equal `false`.
- **main-thread-confinement**: all three settings MUST be read and written
  only on the UI's main execution context; that confinement comes from the
  shared settings types these declarations extend, not from anything
  declared in this file itself.
- **value-round-trip**: for each of the three settings, reading its value
  MUST return the most recently written value for that key, and writing a
  new value MUST persist it so a later read returns it.
- **removal-reverts-to-default**: removing any of the three settings MUST
  cause a subsequent read of its value to return that setting's own
  default value.
- **existence-check**: an existence check MUST return `true` only once a
  value has been explicitly stored for that setting's key, and `false`
  before any write and again after removal.
- **array-setting-json-encoded**: because a list of strings is not one of
  the value types the storage provider stores natively (integer,
  floating-point, boolean, string, binary data, URL, and date types are), a
  write to the skip-patterns setting MUST be JSON-encoded and stored as
  binary data under its key, and a read MUST JSON-decode that data back
  into a list of strings.
- **bool-settings-natively-stored**: because a boolean is one of the value
  types the storage provider stores natively, a write to the
  active-pane-highlight or pointer-follows-focus settings MUST be stored
  directly as a native boolean value under that setting's key, with no
  JSON encoding.
- **not-secure**: all three settings MUST be stored through the non-secure
  storage provider, never a credential-vault-backed secure provider. None
  of the three declarations opts into secure storage, so each defaults to
  the non-secure path, and the settings store dispatches on that flag to
  choose the provider.
- **corrupt-data-falls-back-to-default**: if the stored value for any of
  the three keys cannot be read back as that setting's declared type —
  undecodable data for the skip-patterns setting, or a value that fails to
  cast to boolean for the other two — a read MUST return that setting's
  default value rather than throwing or crashing.
- **change-notification**: a write to any of the three settings' value
  MUST update that setting's observable current-value projection
  synchronously, within the same call, before the write's assignment
  statement returns. The storage provider stores the value, then
  broadcasts the key name, delivered synchronously; each setting's own
  subscription filters for its own name and immediately re-reads and
  assigns its current value, with no queue hop.
- **no-pattern-validation**: the skip-patterns setting MUST accept and
  store any list of strings as its value, including empty strings,
  duplicate entries, and strings that are not valid glob syntax. The
  declaration performs no check of its own on the strings it stores; the
  documentation states the scanner is handed this list as a plain
  parameter specifically so its own walk logic — not this setting — can be
  tested independently of a settings store.
- **highlight-active-pane-override**: the active-pane-highlight setting's
  own documentation states that a per-project override supersedes it; the
  consumer that implements this precedence reads the override when
  present, falling back to this setting's value otherwise, confirming
  that, when present, the override MUST take precedence over this
  setting's value.

