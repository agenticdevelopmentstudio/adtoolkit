
- A model that nobody retains is released even if started.
- A failed write of an entry that no longer exists reports that, not "locked".
- Moving an entry to its own status writes no audit.
- A running timer ticks locally between polls; the model supplies only the start instant.
- The first poll reads everything even if no consumer has yet said it is showing, because a window restored at launch is on screen first.

