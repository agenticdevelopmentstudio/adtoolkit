
- **Hardcoded English strings**: `rethrowConflict`'s friendly message,
  `A game with slug "<slug>" already exists.` (both `gamesApi.create` and
  `gamesApi.update`), and `textToJson`'s two refusal messages, `Engine
  config must be valid JSON.` and `Data must be valid JSON.`, are fixed
  English with no lookup table, i18n key, or locale parameter anywhere in
  this module.

This is a plain, honestly-reported fact about the current source, not a
hidden gap (see Compliance).

