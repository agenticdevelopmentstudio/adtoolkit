
This module is the status dashboard's platform taxonomy. Its header comment
states its purpose: "glyph, brand color, and badge label for each deploy
platform (plus the http/dns health checks). One module owns 'what a platform
looks like', so adding a platform is a single edit here."

It exports six pure operations:

- the platform-glyph operation returns a Unicode glyph.
- the platform-color operation returns a theme color role.
- the platform-label operation returns an upper-case badge label.
- the short-platform-label operation returns a compact label for dense
  strips.
- the deploy-status-color operation returns the theme color role for a
  deploy status dot or label.
- the deploy-status-label operation returns a short text label for a deploy
  status.

The module has no state, no I/O and no side effects. It draws its deploy
status vocabulary and its color-role map from two sibling modules. The
callers are dashboard components and views that render deploy or platform
badges; they render the returned strings and never branch on them. The
server-side status vocabulary is specified in [Monitor Deploy
Status](adtoolkit://cookbook/status/service/monitor/deploy-status).

