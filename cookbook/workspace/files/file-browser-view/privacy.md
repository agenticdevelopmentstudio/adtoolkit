
- **Data collected**: Directory locations the user explicitly chooses
  through the system directory picker when adding a root, plus the
  location/selection state the user creates by clicking in the tree (held
  in the selection state). Nothing is collected automatically or without a
  user action.
- **Storage**: This component does not itself write anything to persistent
  storage. Changes flow out through change callbacks on the directories
  state and the restoration state, which a host supplies and which decide
  whether and where to persist them; the tree display configuration
  separately names a persisted-settings key that a different component
  (custom file-type mappings) owns, not this one.
- **Transmission**: None. This component makes no network calls.
- **Retention**: Determined entirely by the host through the change
  callbacks above; this component keeps the roots and selection only in
  memory for as long as the component and its injected state live.

