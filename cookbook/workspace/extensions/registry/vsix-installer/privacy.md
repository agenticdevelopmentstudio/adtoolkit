
- **Data collected**: `VSIXInstaller` collects nothing beyond what the caller
  already supplies as arguments — the archive bytes, the registry's metadata
  fields it is given (`detail`), and whatever `expectedIdentifier`/`source` the
  caller passes. It reads no field from the archive's manifest that it did
  not already need for the checks above (identifier, version, `engines.vscode`,
  `displayName`, `browser`, `main`).
- **Storage**: The extension's expanded payload is written, unencrypted, as
  ordinary files under `installDirectory` — a persistent, caller-chosen
  location, typically `~/Library/Application Support/<App>/Extensions` in the
  shipping app (doc comment). A superseded copy and, briefly, a
  crash-orphaned aside are also written there under a hidden name before being
  removed.
- **Transmission**: `VSIXInstaller` itself makes no network request; on the
  registry path, `install(_:using:)` calls into `OpenVSXClient` to fetch the
  archive and its verification artifacts, so whatever `OpenVSXClient`'s own
  Privacy section states about that transmission applies here as well.
- **Retention**: The installed directory persists until a later install
  supersedes it (`supersede-by-manifest-identity`) or a caller elsewhere in the
  app removes it; `VSIXInstaller` sets no expiry or retention policy of its
  own on anything it writes.

