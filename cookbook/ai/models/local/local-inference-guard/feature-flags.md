
Not applicable: the guard defines no feature-flag or on/off settings-key
gate of its own; the `ai_guard_warn_pct` / `ai_guard_block_pct` keys it
reads via the settings reader are numeric thresholds (see Configuration),
not a flag that enables or disables the guard.

