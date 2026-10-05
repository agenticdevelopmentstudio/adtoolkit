
- **modes**: The rounding MUST offer exactly two modes, upward, whose raw value is `up`, and nearest, whose raw value is `nearest`, and MUST expose both.
- **upward**: Upward MUST round a positive value to the next whole multiple of the increment; a value already a multiple MUST stay unchanged.
- **nearest-half-up**: Nearest MUST round to the closest multiple of the increment, with an exact half going up.
- **zero-increment-passes**: An increment of zero or less MUST mean no rounding: the value passes through, and MUST NOT round to zero.
- **nonpositive-value-is-zero**: A value of zero or less MUST round to zero in both modes, so nothing never acquires a minimum increment.
- **value-guard-first**: The nonpositive-value rule MUST take precedence over the zero-increment rule.
- **integer-only**: The arithmetic MUST be entirely in integers.

