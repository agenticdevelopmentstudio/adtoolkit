
- **Data collected**: Not applicable — the component collects no data of
  its own; it displays the store's themes and reports the user's picked
  theme id through the standard active-theme write path.
- **Storage**: The default theme store persists custom themes and the
  active theme id through the shared settings store (persisted keys for
  custom themes and the active theme id); the component performs no
  storage access of its own beyond constructing that default and
  reading/writing through the control and view model it wires up.
- **Transmission**: Not applicable — no networking call appears in this
  component.
- **Retention**: The view retains only its own subviews (the control, the
  preview) and its subscription for its own lifetime; the theme selection
  it commits persists in the shared settings store independent of the
  view's own lifetime (see Storage).

