
This module holds the status dashboard's rendering projections of the server-owned board. Its header comment is explicit that it derives nothing the server owns: row construction lives in a separate module, problem derivation and indicator state belong to the server's board, and a row's environment tier is stamped by the server before the row ships. What remains here are small, pure, synchronous helpers:

- the sign / pill vocabulary — a sign state (one of three values) plus a count.
- the problems-to-indicator operation — sign state and count over the problems a pane is showing, transcribed from the server's own indicator rule.
- the wire-indicator translation map — the one translation from the server's wire-level indicator vocabulary (`operational`/`degraded`/`outage`) to the sign-state vocabulary.
- the deploy-counts operation — build/deploy/failure tallies for the stats strip.
- the activity-window-caption operation — the "24h" / "7d" caption for the window the server chose.
- the headline operation — the headline shared by the mobile hero sign and the desktop top-bar pill.
- the real-environment-deploy predicate (a record form and a platform/environment form) — excludes preview builds from a specific deploy provider.

Consumers read the problems-to-indicator operation and the wire-indicator translation map for the overview tab and the portfolio indicator; the deploy-counts operation and the activity-window-caption operation for the stats strip; the headline operation for the hero sign, the top-bar pill and the wallboard pill; and the sign-state vocabulary for the status sign and its sublabel. The record form of the real-environment-deploy predicate has no caller in the client outside this module and its own test; the server carries its own copy of the same rule. Types come from Board Types (the activity row, indicator and problem shapes) and the module's own deployment-record shape.

