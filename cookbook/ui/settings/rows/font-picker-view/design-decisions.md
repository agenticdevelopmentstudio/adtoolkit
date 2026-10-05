
**Decision**: `viewModel.onChange` is overwritten unconditionally in `init`,
replacing any handler already registered on that `FontViewModel` instance.
**Rationale**: Mirrors the same closure-property-assignment pattern
documented at `adtoolkit://cookbook/ui/settings/rows/color-picker-view#requirements/owns-on-change`;
the view provides no way to compose with an existing observer.
**Approved**: pending

**Decision**: A single font pick can trigger `sync()` up to three times (one
synchronous call from `button.onChange`, and up to two further asynchronous
calls from `FontViewModel`'s `nameObserver`/`sizeObserver`, each hopping to
the next main-queue turn) with no debouncing or deduplication.
**Rationale**: `sync()` always re-reads current state from `viewModel` rather
than accumulating deltas, so the repeated calls are redundant but
observably idempotent; the source accepts that redundancy rather than
adding a guard, consistent with `UserSettingObserver`'s own documented
choice to hop to the main queue for every mouse-drag-safe update rather than
coalescing them.
**Approved**: pending

**Decision**: The disabled-state dimming uses a hardcoded `0.4` alpha on
`label`, local to this file, rather than a shared "disabled alpha" token
used elsewhere in the row family.
**Rationale**: No other file under `ComposableSettingsWindow/Views` sets this
exact value or references a shared constant for it; this recipe documents
the value as-is rather than inventing a token the source does not use (see
the open question on minimum-contrast-ratio under Accessibility).
**Approved**: pending

**Decision**: The component performs no contrast check of its own: the label's color and the surface behind it, further dimmed to a fixed 40% opacity when the row is disabled, resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
**Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
**Approved**: pending

