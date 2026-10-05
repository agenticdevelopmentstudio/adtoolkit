
This module is the status dashboard's "single source for small string shapes that were otherwise copy-pasted across the fetchers, row builders, and config surfaces" (its header comment). It exports three pure, synchronous operations:

- the pluralization operation — "count plus a correctly-pluralized noun", so "the banner, the Auto Configure summary, and the Config badges agree on copy". Called from several banners and config surfaces across the dashboard.
- the short-sha operation — "Short commit sha (GitHub's 7-char form), or no result". Called from the overview tab, the deploy list, and the row-building logic.
- the commit-first-line operation — "First line of a commit message, capped at a maximum length, or no result", because "Commit messages are 'subject\n\nbody'; rows show only the subject". Called from the row-building logic.

The module owns no state, performs no I/O, and imports nothing. Behavior of the short-sha and commit-first-line operations is asserted by the module's own test suite; the pluralization operation has no test.

