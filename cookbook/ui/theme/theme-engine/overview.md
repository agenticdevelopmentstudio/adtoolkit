
This recipe covers this toolkit's own half of the theme engine, layered on
top of a shared model — a theme, its color roles, and the semantic palette
that derives colors from it — specified separately by
[Theme Engine (shared model)](agenticdevelopertoolkit://recipes/theme-engine).
This layer adds four things on top of that model, each in its own concern:

- a syntax-role vocabulary (the ten syntax attributes a source editor
  paints), a syntax style (color + bold + italic), and the
  `syntax.<role>[.bold][.italic]` key grammar that stores those styles
  inside a theme's free-form override map;
- an importer that parses a VS Code color-theme JSON(C) file into a theme:
  palette, appearance, six semantic role overrides, syntax styles derived
  from `tokenColors` rules, and `include`-chain resolution with a
  containment root and a depth bound. It also adds an operation that stores
  the imported result as a locked, already-imported theme;
- a storage backing that persists custom themes and the active theme id
  through this app's settings storage under the historical keys, plus a
  no-argument convenience construction for the theme store;
- on desktop platforms, the wiring from that storage to the platform's own
  appearance/dark-mode signal, also available as a no-argument convenience
  construction for the theme manager.

Use it when a host needs VS Code themes, per-role syntax colors that travel
with a theme, or a theme catalog persisted in the app's settings storage. It
has no visual surface of its own.

