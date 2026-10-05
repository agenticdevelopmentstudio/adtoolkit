
The live timer list shows one row per running timer and a line of text when none is running. Rows are kept by id when the timers change, so a timer that is still running keeps its row and its clock never jumps; rows are rebuilt only when timers start or stop. Only a hand-started timer shows a stop button. The list owns a ticker and runs it only while it can be seen: in a window that is on screen and not covered, with something running. When it becomes visible again the clocks catch up at once.

