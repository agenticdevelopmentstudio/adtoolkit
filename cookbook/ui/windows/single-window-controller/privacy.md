
The frame (position and size) and visibility of each window are persisted to
disk by the window frame manager, keyed by the window ID, whenever the
corresponding frame/visibility persistence flags are enabled (the default
behavior set enables both). This class itself does not choose the storage
location or retention policy — it is the trigger point (via the move,
resize, will-close, show, and dismiss callbacks) that calls into the window
frame manager's persistence, which retains the last-known frame and
visibility indefinitely until a caller outside this class clears it. No
content, document data, or personally identifying information is captured
by this class; only window geometry and shown/hidden state are stored.

