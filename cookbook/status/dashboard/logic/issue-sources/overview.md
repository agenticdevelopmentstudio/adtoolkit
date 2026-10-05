
This module declares where a status-board row or Problem came from: DNS resolution, the HTTP probe, the GlitchTip error tracker, or one of four deploy providers. Its doc comment explains why `glitchtip` is a separate source: "the other sources answer 'is the thing reachable', it answers 'is the thing THROWING'".

It exports five things:

- the issue-source vocabulary, a closed set of seven source identifiers.
- the source label map, giving display labels for the source filter and badges, one per vocabulary member.
- the source order list, giving the canonical order for the source filter UI.
- the issue-source guard operation, which decides whether a raw platform or source string is a member of the vocabulary.
- the stuck-deploy threshold, the number of milliseconds a build may sit BUILDING before the backend counts it as stuck.

The module is a client-side MIRROR of the server's own issue-sources module: "same union, same labels, same order". The server file also holds the judgment functions that decide whether an HTTP check, a deploy, or a platform stream counts as bad or stuck. The client copies only the vocabulary and the threshold constant. It has no state, no I/O and no side effects.

Consumers in the client: the source-filter state ([Source Filter](adtoolkit://cookbook/status/dashboard/state/source-filter)) seeds its selection from the source order list; the board types ([Board Types](adtoolkit://cookbook/status/dashboard/logic/board-types)) type board rows with the issue-source vocabulary; the row-building logic, the activity panel, the overview tab and the global panel read the labels, order and guard.

