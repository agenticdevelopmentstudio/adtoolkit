
The live timer row shows one running timer: a dot saying whether it was started by hand or automatically, a title, an optional smaller subtitle, an elapsed clock and a stop button. It knows nothing about billing; the caller writes whatever it wants into the title and subtitle. A separate ticker object schedules one repeating tick for a whole list of rows so the rows stay a rendering concern.

