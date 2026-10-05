
- **Data collected**: File and directory paths the user browses, expands, and
  selects on their own local filesystem; the presence of open documents and
  their dirty state, read from the injected document store. Nothing is
  collected automatically beyond what the user's own filesystem and open
  documents already contain.
- **Storage**: This component does not itself write to persistent storage.
  Disclosure and selection changes flow out through the restoration model's
  change notification, a callback the host supplies and which decides
  whether and where to persist them; this component only updates the
  expanded-state and selected-path fields on that shared object.
- **Transmission**: None. This component makes no network calls.
- **Retention**: Determined entirely by the host through the restoration
  model's change notification; this component keeps disclosure and selection
  state only in memory, for as long as the component and its injected model
  objects live.

