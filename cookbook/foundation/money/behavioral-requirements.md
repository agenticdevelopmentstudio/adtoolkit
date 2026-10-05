
- **integer-hundredths**: The amount MUST be an integer count of hundredths of the currency's major unit, never a fraction, and the type MUST NOT use a floating-point number.
- **currency-default-usd**: The currency MUST default to `USD` when the caller omits it.
- **currency-carried-no-conversion**: The currency code MUST be carried so a total can refuse to mix currencies; no conversion between currencies MUST be performed anywhere.
- **same-currency-test**: The type MUST report whether two amounts share a currency, by exact code equality.
- **mixed-currency-is-programmer-error**: Comparing, adding or subtracting amounts of different currencies MUST fail as a programmer error, never return a result or a false.
- **add-subtract**: Adding or subtracting same-currency amounts MUST return an amount in that currency whose hundredths are the sum or difference.
- **ordering**: Same-currency amounts MUST be ordered by their hundredths.
- **sum-of-list**: Summing a list MUST add through the addition rule, so a mixed list fails; an empty list MUST sum to zero in the given currency (default `USD`) rather than nothing.
- **amount-from-seconds**: The amount for a number of seconds at an hourly rate in hundredths MUST be seconds times rate divided by 3600, rounded half-up, entirely in integers.
- **amount-zero-guards**: The seconds-to-amount function MUST return zero when the seconds are zero or negative or when the rate is zero.
- **amount-sign-preserved**: A negative rate MUST produce a negative amount whose magnitude is rounded half-up, so rounding is symmetric about zero.
- **codable-equatable**: The amount MUST be encodable, decodable and equal exactly when hundredths and currency are both equal.

