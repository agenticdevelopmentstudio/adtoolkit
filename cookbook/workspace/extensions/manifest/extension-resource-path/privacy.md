
- **Data collected**: none in the sense of device- or user-identifying
  telemetry. However, the resolved value carried by a thrown escape error,
  and every location the home-dotfolder and application-support location
  factories derive, is an absolute local file-system path that necessarily
  embeds the local account's home-directory name — because both are
  derived from the process's home directory and the user-domain
  Application Support directory.
- **Storage**: none. Every value this component produces is held only in
  the caller's own variables for as long as the caller keeps it; this
  component writes nothing to disk.
- **Transmission**: none performed directly by this component — it does no
  networking. Downstream, a snippet-loading failure's reason and a
  theme-import failure's message carry a resolved path (and the account
  name it embeds) into structures a settings panel may display to the
  extension author; how far that display surface propagates is outside
  this component.
- **Retention**: for the lifetime of whichever value — a location, a
  thrown error, or a search-path list — the caller holds; this component
  itself retains nothing once a call returns.

