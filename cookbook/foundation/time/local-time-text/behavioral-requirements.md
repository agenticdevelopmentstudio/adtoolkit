
- **clock-text**: The clock text for an instant MUST be `h:mm a` in a locale that uses a 12-hour clock (`2:05 PM`) and `H:mm` in one that does not (`14:05`), in the given time zone and locale.
- **day-and-clock**: The day-and-clock text MUST be the month and day in the locale's own order, a comma and space, then the clock text (`Sep 24, 2:05 PM`, `24 Sep, 14:05`).
- **twelve-hour-detection**: The locale MUST be classified as 12-hour when its localized hour template contains a day-period marker.
- **parse-locale-first**: Parsing typed text MUST try the viewer's own clock pattern first, then `h:mm a`, `h:mma`, `h a` and `ha` in a fixed POSIX locale.
- **parse-twenty-four-hour**: If no marked pattern matches, parsing MUST try `H:mm` and `H`, so `14:05` and a bare `14` are accepted whatever the locale.
- **parse-ambiguous-bare-time**: In a 12-hour locale a bare time whose hour is 1 to 12 and which carries no day-period marker MUST return both readings, the typed hour and that hour plus twelve; otherwise it MUST return one reading.
- **parse-not-a-time**: Text that matches no pattern, or that is empty after trimming whitespace, MUST return no readings.
- **parse-strict**: Formatters MUST be non-lenient, so out-of-range fields do not wrap into a valid time.
- **nearest-instant**: Resolving a typed clock against a reference instant MUST consider the reference's day and the days either side in the given zone, for every candidate clock, and MUST return the instant closest to the reference, nothing if none can be built.
- **start-of-day**: The start of a `yyyy-MM-dd` day MUST be the instant that day begins in the given zone, or nothing when the text is not a day.
- **integer-seconds-between**: The seconds between two instants MUST be whole seconds computed without a floating-point intermediate.
- **formatter-cache**: Formatters MUST be cached by pattern, zone identifier and locale identifier, and the cache MUST be guarded by a lock so any thread may format.

