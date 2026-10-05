
No file in this domain calls a logger or any platform logging facility.
Every failure this component detects (a thrown 404 mapped to `null`, an
unrecognized author kind mapped to `"customer"`, a network error) is either
resolved to a documented fallback value or surfaced to the caller as a
thrown error; any logging of that failure is the responsibility of the
caller or host application, not of this domain component.

