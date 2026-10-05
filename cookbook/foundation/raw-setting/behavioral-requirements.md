
- **bool-true-spellings**: A boolean read MUST return true for `1`, `true`, `yes` and `on`, compared case-insensitively after trimming whitespace and newlines.
- **bool-false-spellings**: A boolean read MUST return false for `0`, `false`, `no` and `off`, under the same comparison.
- **bool-fallback**: A boolean read of text that is absent, empty or any other spelling MUST return the caller's default, so a caller whose safe answer is off passes false.
- **int-parses-trimmed**: An integer read MUST trim whitespace and newlines and parse a base-ten integer; text that is absent or not an integer MUST return the caller's default.
- **int-clamps-to-range**: An integer read that parses MUST be clamped into the caller's closed range rather than refused, so an over-eager hand edit means the nearest allowed value.
- **int-default-not-clamped**: The default returned for absent or malformed integer text MUST be returned as given, without clamping.
- **string-trims**: A string read MUST return the text trimmed of whitespace and newlines.
- **string-fallback**: A string read MUST return the caller's default when the text is absent or empty after trimming.
- **stateless**: The functions MUST hold no state.

