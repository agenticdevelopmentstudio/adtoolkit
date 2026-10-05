
This component is the gamification realm client: the owner/admin-scoped
data layer for ONE ecosystem's gamification "realm" — its configuration
(mode, skin, per-surface toggles, seasons, timezone), its effective catalog
(platform-default badges and level rungs merged with the realm's own
overrides), realm-owned badge management, wholesale level-ladder
replacement, a manual replay trigger, and realm custom event-type
management. This logic backs the per-product Gamification panes — a
single settings pane and a four-topic rail alike — reaching the backend's
realm-config route family (and a sibling replay route) through a host
proxy. This is a **logic** component: it renders nothing — it is a plain
request-based client and its wire shapes, consumed by separate UI panes
that are not part of this component's given sources.

