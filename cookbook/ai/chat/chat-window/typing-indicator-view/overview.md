
The Typing Indicator View shows three small dots inside a rounded pill and, once started, pulses them one at a time in a left-to-right chase to signal that the assistant is composing a reply — an animated typing indicator built from three pulsing dots. It is theme-aware — the pill's fill and the dots' color are resolved from the active theme palette and reapplied on every theme change — and it owns no state beyond what it needs to run and stop that animation: the caller starts it explicitly with `startAnimating()`, and it stops implicitly when removed from the view hierarchy.

