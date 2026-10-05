
- **Data collected**: Per window id, a persisted window state (frame
  placements per screen set, including display identifier and localized
  display name fingerprints) and a visibility boolean; document URLs
  passed to the platform's recent-documents list.
- **Storage**: Window state and visibility in the settings store's
  non-secure provider (the platform's local preferences store by default)
  or directly in that same local preferences store; recents in the
  platform's recent-documents store. The namespace prefix is a hash, so a
  build path never reaches the preferences file.
- **Transmission**: None from this component; a settings store backed by
  an iCloud-syncing provider syncs these keys through that provider.
- **Retention**: Until removed by the remove-state or remove-visibility
  operations, or the preferences domain is deleted; recents are capped by
  the platform's recent-documents limit setting.

