
No file in this domain calls a logger or any platform logging API. Every
failure this component detects is either resolved to a documented
fallback (fetching a single team's `null`) or surfaced to the caller as a
thrown error; logging that failure is the responsibility of the caller or
host application, not of this domain component.

