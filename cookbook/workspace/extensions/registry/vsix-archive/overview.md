
The VSIX archive concept is a stateless collection of two operations on a
downloaded `.vsix` file: verification, which checks the raw archive bytes
against whatever digest and Ed25519 signature the registry published for
them, and expansion, which unpacks the archive onto disk through the
platform's own archive-extraction utility under a timeout and a
decompressed-size ceiling. A `.vsix` is a zip whose extension tree lives
under an `extension/` subdirectory alongside packaging metadata this host
does not read; resolving the payload directory is the one place that
subdirectory name is spelled out.

Both operations are read-only with respect to the network: nothing here
downloads anything. The one caller in this codebase fetches the archive
bytes and the optional digest/signature/key text over HTTP itself, then
calls verification followed by expansion synchronously, inside a dedicated
blocking-work context, because neither operation suspends and both can hold
a thread for the length of a 512 MB download's worth of hashing or an
extraction run.

Verification's contract states plainly what its two checks do and do not
establish: the digest and signature are both checked against values the
*registry* published in the same response that named the archive, never
against an out-of-band publisher key, so a registry serving altered bytes
under a key of its own passes every check here. That is why a fully
verified result is named "registry attested" rather than "verified."

