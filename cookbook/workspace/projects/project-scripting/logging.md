
This surface and the three wrapper types make no logging call. A branch
that fails to resolve is not logged here at all; any underlying git
failure is recorded once, upstream, by the git command log (see
`adtoolkit://cookbook/workspace/projects/branch-controller`), not a
second time by this surface.

| Event | Level | Message |
|-------|-------|---------|
| (none) | — | This surface and its three wrapper types emit no log messages. |

