
- **reads-through-source**: Reading the value MUST return what the underlying source currently holds, by asking the source at read time rather than caching a copy.
- **writes-through-source**: Writing the value MUST hand the new value to the underlying source before anything is reported.
- **notifies-after-write**: After a write, the observer MUST invoke its change callback, if one is set, with the value that was written, and the source MUST already hold that value when the callback runs.
- **notifies-on-main-queue**: The change callback MUST be delivered through the main dispatch queue and not through a run-loop mode, so it still arrives while the user is tracking a mouse drag.
- **callback-is-optional**: A write with no change callback assigned MUST succeed and report nothing.
- **skips-delivery-when-released**: A delivery still queued when the observer is released MUST be dropped without effect.
- **closure-form**: The component MUST provide a form built from a getter, a setter and an optional change callback, so a caller can bind a view to values that are not in the settings store.
- **persisted-form-conforms**: The persisted-settings observer MUST satisfy the same contract as the closure form.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

