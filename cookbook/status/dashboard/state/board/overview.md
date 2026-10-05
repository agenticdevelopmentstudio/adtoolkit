
This logic is the status dashboard's one source for the server-derived board. It fetches `GET /board` through the injected API client, polls every 60 seconds, and refetches immediately whenever the live transport ingests a frame. Per its own documentation it "fetches and renders; it does not derive, accumulate, or persist."

Its defining contract is that `board` is non-null only when the board can back a current claim. A board that has not arrived, whose request failed, whose read clock (`generatedAt`) has gone old, whose data clock (`dataAsOfMs`) lags the read clock past a cadence-scaled window, or that rests on no observation at all, is returned as `board: null` together with a reason naming which of those it is. Consumers get the staleness verdict by construction instead of each re-deriving it. The rules and thresholds themselves live in a separate staleness component; this logic is the single call site that applies them.

Use it anywhere a view needs the portfolio board (the overview, the header pill, the global panel view). Word the "unknown" message per cause from `reason`; never re-derive staleness downstream.

