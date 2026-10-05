
- **trim-and-uppercase**: Normalizing MUST trim surrounding whitespace and newlines and upper-case the text before checking it.
- **three-letters**: The normalized text MUST be exactly three characters, each an ASCII letter `A` to `Z`; anything else MUST yield nothing.
- **shape-only**: Normalizing MUST NOT check the code against any list of real currencies; `XYZ` is accepted.
- **single-owner**: This shape rule MUST be the only one used to accept a currency code, so no screen accepts a code another refuses.

