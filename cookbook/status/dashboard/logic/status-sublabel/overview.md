
This logic provides one pure, synchronous function, the sublabel-building function, that returns the one-line caption shown under the status headline. When the board is clear it reads like "12/12 endpoints healthy · no failed builds". Otherwise it is a grouped breakdown of the problem rows, such as "2 down · 1 failed build", and the doc comment requires it to account "for EVERY problem so the parts sum to the indicator count".

The doc comment says the function is "Shared by the mobile hero and the desktop top-bar pill". In the current tree its only caller is the overview tab view, which passes the result to the big indicator view as its sublabel. The inputs are typed by the indicator state (specified in [Overview Projections](adtoolkit://cookbook/status/dashboard/logic/overview)) and a row (specified in [Row Model](adtoolkit://cookbook/status/dashboard/logic/row-model)). The function reads only a row's `statusWord`.

This logic also holds a private table, the sublabel-phrase table, which maps a problem row's status word to a function that formats a count into a phrase.

