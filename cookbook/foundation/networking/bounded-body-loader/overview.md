
This component is a single internal type, visible only within its own
module: a bounded HTTP body reader that reads a response body into memory
at the rate the system delivers it, and refuses one that grows past a
caller-supplied ceiling. Its one operation — read the body at a URL,
bounded by a limit — is the sole caller-facing surface, used by an
extension-registry client for both its package downloads (an installable
bundle, a signature archive, a public key) and its metadata reads (search,
detail) — one bounded-read rule shared by two ceilings. The design exists
because the two more obvious ways to read a response body could not do
this: one cannot be bounded at all, and the other can be bounded but reads
roughly two orders of magnitude slower against a local benchmark because it
yields the body one byte at a time. Reading whole chunks at the transport's
own rate, with the ceiling checked after each chunk, gets both properties.

