
- **Data collected**: None — the component holds only the help content
  and the presenter/content-view references handed to it by its caller;
  it originates no data of its own.
- **Storage**: Not applicable — the source performs no persistence of any
  kind. (Whether help-visibility is remembered across launches is decided
  by the assigned help presenter's own implementation, outside this
  component's source — see Platform Notes for the source's own example.)
- **Transmission**: Not applicable — no networking call appears anywhere
  in source.
- **Retention**: The currently installed content view and the most
  recently set help content are held in memory as private state for the
  component's own lifetime, and are replaced (not appended to) on every
  subsequent set-content/set-help call; nothing persists past
  deallocation.

