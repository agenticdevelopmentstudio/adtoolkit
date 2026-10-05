
- **Data collected**: None of this scope collects data on its own; the
  form model and validator operate only on whatever field values the
  host's form specification asks the user to enter (arbitrary strings,
  booleans, numbers, dates, or string sets) - the engine itself has no
  knowledge of whether any given key is sensitive.
- **Storage**: Nothing in this scope persists anything to disk, a
  database, or a settings store; the form model's values/baseline and the
  controller's levels/selection/detail are in-memory only and are
  discarded when the owning object is released.
- **Transmission**: The controller transmits whatever the data source's
  root-level/child fetch implementation does internally (outside this
  scope); saving transmits whatever the host's save-action callback does
  internally. Neither performs a network call itself.
- **Retention**: Not applicable - nothing here is retained beyond the
  lifetime of the in-memory controller/form-model instance.

