
- **Data collected**: None. This component neither reads nor stores any credential, token, or user-identifying data; it only encodes, decodes, and reassembles the components of a URI string a caller already holds.
- **Storage**: A `Uri` instance's own fields live only in memory, frozen for the lifetime of the JavaScript object; the class constructor itself is cached for the lifetime of its extension environment (**class-installed-once-per-context**).
- **Transmission**: Nothing in this component transmits data off-device; it performs no network I/O.
- **Retention**: A `Uri` instance and the cached class constructor are retained only as long as their extension environment is retained; nothing here persists across that lifetime.

