
- A stored value of the wrong type falls to the setting's default.
- Out-of-range stored values are not clamped by the holder; the billing preferences snapshot clamps them to the shared ranges when it reads the same keys.
- Two holders built from the same key set observe each other's writes through the settings store.

