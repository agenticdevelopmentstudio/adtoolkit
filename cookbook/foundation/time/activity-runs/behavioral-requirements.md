
- **span**: A span MUST hold a start stamp and an end stamp, compared by value equality, from the first stamp of a run to the last.
- **split-at-idle-gap**: Splitting MUST take ascending stamps and an idle gap and close the running span whenever the gap to the next stamp is strictly greater than the idle gap; the closed span MUST end at the previous stamp, never extending into the idle stretch.
- **equal-gap-does-not-split**: A gap exactly equal to the idle gap MUST NOT split; the stamp joins the running span.
- **single-stamp-span**: A stamp after a split, or the first stamp, MUST open a span whose start and end are both that stamp.
- **no-stamps-no-spans**: An empty sequence of stamps MUST produce no spans.
- **streaming-splitter**: A streaming splitter MUST accept stamps one at a time in ascending order, expose the spans closed so far, and apply the same split rule as the one-shot split.
- **close-run**: The streaming splitter MUST offer closing the running span at a boundary the stamps do not show, such as the next stamp belonging to a different session; closing with no running span MUST do nothing.
- **finish**: Finishing MUST close the running span and return every span.
- **union**: The union MUST sort intervals by start and merge any intervals that overlap or touch (next start less than or equal to the current end), extending the merged end to the larger end.
- **union-ordering-only**: The union MUST need only ordering of stamps, so it MUST work for fixed-width ISO strings as well as numbers.
- **union-length**: The union length MUST be the sum of the merged spans' lengths, counting overlaps once, as wall-clock time.
- **sendable-when-stamp-is**: Spans MUST be safe to share across threads whenever their stamp type is.

