
- **round-to-increment**: The function MUST return `rawSeconds` rounded to a whole multiple of `roundingMinutes` minutes.
- **mode-up**: Mode `up` MUST round to the next increment, leaving an exact multiple unchanged.
- **mode-nearest**: Mode `nearest` MUST round half-up to the closest increment.
- **unknown-mode-up**: Any other mode string MUST behave as `up`, the default, rather than billing nothing.
- **non-positive-increment-passthrough**: A `roundingMinutes` of zero or less MUST mean no rounding: the raw seconds pass through unchanged.
- **non-positive-raw-zero**: Zero or negative raw seconds MUST bill zero, so a session with no time never acquires a minimum increment.
- **once-per-entry**: Callers MUST apply rounding to an entry's total raw seconds, not to each segment.

