
Not applicable: the source declares no feature-flag or configuration-flag
lookup — every call to `install(_:using:)`, `install(archive:...)`, or
`recoverInterruptedInstalls()` runs the same fixed logic unconditionally
(traced to the absence of any flag check anywhere in the source).

