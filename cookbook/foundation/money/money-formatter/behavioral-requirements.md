
- **integer-hundredths**: The formatter MUST take and return amounts as integer hundredths of the major unit and MUST NOT require a floating-point number to exist at any step.
- **construction**: The formatter MUST be built from a currency code (default `USD`) and a locale (default the current locale); the locale decides symbol placement, grouping and the decimal separator.
- **display-two-fraction-digits**: Display MUST always show exactly two fraction digits for every currency, with the currency symbol and grouping, so rounded rows add up to the exactly-summed total and no currency acquires a third digit the stored value never had.
- **display-money-uses-own-currency**: Formatting a money value MUST follow that value's own currency, not the formatter's default.
- **editable-string**: The editable form MUST be a plain number with two fraction digits, no currency symbol and no grouping, in the locale's decimal separator, suitable for a text field while someone is typing.
- **parse-accepts-pasted-text**: Parsing MUST accept a currency symbol or code, grouping separators, surrounding spaces and either decimal separator.
- **parse-both-separators**: When both a period and a comma are present, the last separator MUST be the decimal point and the other kind MUST group; the decimal kind MUST appear exactly once.
- **parse-repeated-separator-groups**: When one kind of separator appears more than once, it MUST group and there is no decimal point.
- **parse-single-separator**: When one separator appears once: if it is the locale's decimal separator it MUST be a decimal point; if it is the locale's grouping separator it MUST group only when exactly three digits follow it and a non-zero integer part precedes it, and otherwise MUST be a decimal point.
- **parse-ambiguous-refused**: A single separator that is neither of the locale's separators, with exactly three digits after it and a non-zero integer part, MUST be refused as ambiguous.
- **parse-grouping-in-threes**: Grouping MUST be in groups of exactly three digits after a leading group of one to three, and all before the decimal point; otherwise parsing MUST return nothing.
- **parse-sign**: A leading hyphen-minus or Unicode minus sign MUST make the amount negative; a leading plus MUST be ignored; a sign after any digit or separator MUST be refused.
- **parse-no-digits-refused**: Text with no digits, including a lone sign or a lone currency symbol, MUST return nothing rather than zero.
- **parse-half-up**: More than two fraction digits MUST round half-up to hundredths using decimal arithmetic, not binary floating point.
- **parse-overflow-refused**: An amount too large for the integer width MUST return nothing instead of wrapping.
- **parse-stray-characters**: Letters, whitespace, apostrophes and currency symbols MUST be ignored; any other character MUST make the text unreadable.

