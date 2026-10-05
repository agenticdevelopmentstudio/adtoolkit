
- **hours-minutes**: The reading form MUST be `Nh Mm`, with the hour part omitted when zero (`45m`) and the minute part omitted when zero (`2h`); seconds below a minute MUST round down to `0m` rather than imply precision the rounding rules have discarded.
- **decimal-hours**: The decimal-hours form MUST be seconds divided by 3600 rounded half-up at a configurable number of places, default 2, computed entirely in integers (`8100` seconds is `2.25`).
- **decimal-places-clamped**: A negative number of places MUST be treated as zero, in which case the result has no decimal point.
- **clock-form**: The clock form MUST be `H:MM:SS`, with hours not zero-padded and not wrapped at 24, and minutes and seconds two digits.
- **negative-clamps-to-zero**: Every formatter MUST treat negative seconds as zero.
- **parse-decimal-hours**: Parsing MUST accept decimal hours with a period or a comma (`1.5`, `0.25`, `.5`, `1,5`) and a bare integer, converting the fraction to seconds by digits times 3600 divided by 10 to the power of the digit count, rounded half-up, in integers.
- **parse-clock**: Parsing MUST accept a clock `H:MM` whose minutes are exactly two digits and below 60.
- **parse-units**: Parsing MUST accept an hours part, a minutes part, or both with hours first: `1h 30m`, `1h30m`, `2h`, `90m`, with spaces ignored and the case folded; minutes before hours (`30m1h`) and a fractional unit part (`1.5h`) are refused.
- **parse-six-digit-cap**: Each digit run in a parsed duration MUST be plain ASCII digits and at most six long, so every product stays in range.
- **parse-refuses-the-rest**: Parsing MUST return nothing for negative numbers, empty text, more than one decimal separator, and anything else it does not recognize.
- **policy-is-callers**: Whether a parsed duration is allowed (not zero, not over a day) MUST be left to the caller.

