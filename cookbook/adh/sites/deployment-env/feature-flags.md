
Not applicable: the module implements no feature-flag or remote-config
lookup of its own — the allowlist, the server-side membership check, and
the build-time flag are themselves the primitive that other modules'
feature gates (e.g. a dev-tools-availability flag) are built from, not a
consumer of one.

