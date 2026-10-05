
This policy defines no string-key or localization-table lookup; every
string it produces is a hardcoded English literal composed inline, with no
key system to reference:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no key) | `~<X> GB (~<Y>% of RAM)` | The shared footprint-description core, embedded in the verdict computation's block reason. |
| (none — literal, no key) | `<model> needs <footprint> est.; block threshold is <N>% of <X> GB` | The verdict computation's block reason. |
| (none — literal, no key) | `memory pressure is <level>; deferring local inference` | The pressure-verdict computation's deferred reason, also surfaced by the verdict computation. |
| (none — literal, no key) | `<size> (~<Y>% of RAM)` / `<size> ⚠ large: ~<Y>% of RAM` / `<size> — won't run: exceeds memory budget` | The fit-info computation's per-tier text, shown verbatim by the picker-label computation and by callers such as a model chooser. |

