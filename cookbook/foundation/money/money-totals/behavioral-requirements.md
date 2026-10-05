
- **buckets-per-currency**: The total MUST hold one integer hundredths figure per currency code, and only codes that were added MUST appear.
- **add-amount**: Adding hundredths in a currency, or a money value, MUST add to that currency's bucket, creating it at zero first when absent.
- **add-sequence**: Constructing from a sequence of amounts MUST add each amount into its own currency's bucket.
- **add-totals**: Adding another totals value MUST add every one of its buckets into this one's.
- **never-mixed**: Amounts in different currencies MUST never be combined into one bucket and MUST never be converted.
- **is-empty**: The total MUST report whether nothing has been added.
- **sorted-currencies**: The held currencies MUST be reported in ascending code order, and the amounts MUST be the per-currency money values in that same order.
- **description-wording**: The description MUST format each currency's total with the money formatter for that currency, in code order, joined with ` + `, and MUST be the empty string when nothing was added.
- **value-equality**: Two totals MUST be equal exactly when their buckets are equal.

