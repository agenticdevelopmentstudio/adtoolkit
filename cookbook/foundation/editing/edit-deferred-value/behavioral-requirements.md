
- **initial-state**: A new holder MUST report no edit in flight and hold nothing.
- **begin-editing**: Beginning an edit MUST mark an edit as in flight; offers made from then until it ends are held.
- **offer-passes-through**: Offering a value while no edit is in flight MUST return that value immediately for the caller to apply, and MUST NOT hold it.
- **offer-while-editing-parks**: Offering a value while an edit is in flight MUST return nothing and hold the value as the pending one.
- **newest-offer-wins**: An offer made while an earlier one is still held MUST replace it; only the newest reload is worth applying.
- **end-editing-releases**: Ending the edit MUST clear the in-flight flag, return the held value if any, and leave nothing held.
- **end-editing-safe-twice**: Ending an edit when none is in flight MUST be safe and MUST return nothing; a second end after a release returns nothing.
- **state-readable**: The in-flight flag and the pending value MUST be readable, and MUST be changeable only through the operations above.
- **generic-value**: The held value MUST be generic: the holder places no requirement on what a reload is.

