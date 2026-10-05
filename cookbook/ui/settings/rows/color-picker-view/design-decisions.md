
- **Decision**: Write the reported color into the view model's color on
  every invocation of the color-well handler, with no comparison against
  the current value.
  **Rationale**: The handler only fires in response to a user-driven
  change committed in the system color picker, so a redundant same-value
  write is user-caused and harmless; unlike the sibling captioned slider
  row, whose slider fires continuously during a drag and needs an
  equality guard to avoid a flood of redundant writes on every pixel of
  motion, a color well's action fires once per committed selection, so no
  guard was added here.
  **Approved**: pending
- **Decision**: Overwrite the view model's external-change handler
  unconditionally in the initializer, replacing any handler already
  registered on that view model.
  **Rationale**: Mirrors the same handler-assignment pattern used across
  this row family; the view provides no way to compose with an existing
  observer. This constraint on callers is now captured as the
  **owns-on-change** requirement.
  **Approved**: pending

