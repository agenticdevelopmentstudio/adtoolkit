
This is a yes/no capability axis for a model — four cases, `tools`,
`reasoning`, `vision`, `conversation` — representing whether a model
either has or doesn't have each capability, as distinct from the model's
use facets, which capture a "what is it good for" axis instead. Three of
the four (`tools`, `reasoning`, `vision`) are hard capabilities a serving
gateway can assert directly, reported under many different spellings
(`function_calling` vs. `functionCalling` vs. `tool_use`, and so on); the
fourth, `conversation`, has no gateway flag at all and is derived from the
model's prose via its use facets. This is a **logic** component — no
visual surface — used so a UI can render one column per capability with a
check mark rather than a badge string that can't be scanned down a column.
It is pure: every operation is a function of its arguments, and the type
carries no stored state beyond its own raw value.

