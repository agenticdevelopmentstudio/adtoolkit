
**Decision**: The client mirrors the server's indicator rule instead of computing its own.
**Rationale**: The doc comment calls `indicatorFromProblems` a rendering projection, "not a second opinion about what a problem is". It exists only because a filtered pane needs the rule over a subset; `board-types-parity.test.ts` pins it to the server's `indicatorFor` so it cannot drift again.
**Approved**: pending

**Decision**: `INDICATOR_STATE` is the single wire-to-sign translation.
**Rationale**: One typed `Record<BoardIndicator, IndicatorState>` is exhaustive at compile time, and a key test catches a member removed from both union and map together.
**Approved**: pending

**Decision**: Derive the window caption from the board's own bounds instead of hardcoding "24h".
**Rationale**: The server owns `ACTIVITY_WINDOW_MS`; a hardcoded caption would keep stating the old figure after a server change, "a label that lies without anything failing". Days are used only for whole-day windows of 48h or more, so 47h is never rounded to a window nobody configured.
**Approved**: pending

**Decision**: Tally deploy counts on the client.
**Rationale**: The doc comment allows it because the counts are a tally of rows the server already judged: `step` and `tone` arrive on the wire and the window start is the board's `activityFromMs`.
**Approved**: pending

**Decision**: One `headlineFor` shared by the hero sign and the top-bar pill.
**Rationale**: Sharing the function makes it impossible for the two surfaces to word the same state differently.
**Approved**: pending

**Decision**: Treat Vercel deploys with no environment target as preview builds and exclude them.
**Rationale**: Vercel previews report `environment=null`; they are CI artifacts, and counting a failed preview as "deploy failed" under the project's prod/staging label was a real false positive. The duplicated server copy is described under real-env-server-agreement.
**Approved**: pending

