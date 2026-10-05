
Live Snapshot is the status dashboard's transport for the latest `LiveSnapshot` — "what did the last probe cycle see" (services, deployments, `lastCycleAt`, `probeIntervalMs`, `monitorVersion`, `configDegraded`). It is used by several views at once (the header pill, the overview view, the dashboard view, the board shell, the stale banners, the portfolio indicator state), so its state lives in one store per API client, not per view.

The primary feed is one reference-counted server-push stream connection to `/live/stream`, over which the backend pushes a snapshot notification on every cycle and webhook plus a schedule notification with the next cycle time. The fallback is a poll of the shared cache against `GET /live` every 60 s, gated off while the stream is connected. Live Snapshot also exposes a manual full check (`refresh`, `POST /live/check`) whose spinner holds until the caller's own result lands, and a cheap reachability re-read (`reconnect`).

Live Snapshot does not fold notifications into a durable model; the board state answers "what is wrong" and piggybacks on this feed through frame subscription rather than opening a second connection.

