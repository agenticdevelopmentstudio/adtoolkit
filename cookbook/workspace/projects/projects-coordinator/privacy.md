
The only data this feature logs is a set of local filesystem paths (a
repository's path, at public log-visibility, in the three scan-finishing
error messages) and a repository identifier (at public log-visibility,
in renaming's error message) — both already visible to the user in the
project list and its window titles. Opening a project's error message is
the one exception: it logs no path or id at all, only the caught error
value with no explicit visibility annotation. This feature reads,
stores, or transmits no credential, token, or other personal data, and
makes no network call of its own (see Offline or disconnected state
above).

