
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `context` | context handle | none (required) | Installation and every bridge operation take the target context explicitly; there is no ambient or singleton context. |
| `textGeometryGlobalName` | string (fixed constant) | `"__vscodeTextGeometryClasses"` | The global key installation caches the built `{ Position, Range, Location }` container under; not settable per call. |
| `line`, `character` (`Position` constructor) | number | none (required) | Both MUST be non-negative or the constructor throws, per **position-constructor-validates-line**/**position-constructor-validates-character**. |
| `startLineOrStart`, `startColumnOrEnd`, `endLine`, `endColumn` (`Range` constructor) | four numbers, or two position-like values | none (required) | Dispatch on argument shape, per **range-constructor-four-number-form**/**range-constructor-two-position-form**. |
| `rangeOrPosition` (`Location` constructor, 2nd argument) | position-like, range-like, or falsy | falsy leaves `range` unset | Dispatch on shape, per **location-constructor-position-becomes-empty-range**/**location-constructor-range-reused-by-identity**/**location-constructor-range-like-rebuilt**/**location-constructor-falsy-range-leaves-unset**. |
| `lineDeltaOrChange`, `characterDeltaArg` (`Position.prototype.translate`) | two numbers, a `{lineDelta, characterDelta}` object, or omitted | `0` for each omitted field | Per **position-translate-omitted-defaults-zero**. |
| `lineOrChange`, `characterArg` (`Position.prototype.with`) | two numbers, a `{line, character}` object, or omitted | the receiver's current value for each omitted field | Per **position-with-omitted-keeps-current-value**. |
| `startOrChange`, `endArg` (`Range.prototype.with`) | a position-like value, a `{start, end}` object, or omitted | the receiver's current `start`/`end` for each omitted or falsy field | Per **range-with-dispatch**. |

