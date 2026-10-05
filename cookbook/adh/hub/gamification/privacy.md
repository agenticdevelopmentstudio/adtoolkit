
- **Data collected**: this component collects no analytics of its own.
  It transports realm configuration and gamification-catalog data (a
  realm configuration record, its effective catalog, a badge record, an
  event-type record, and their create/update bodies) — none of which is
  end-user personal data. This component reads, stores, or transmits no
  token or credential directly; the access token attached to every
  request is handled entirely by the shared authenticated-request layer,
  outside this component's own logic.
- **Storage**: not applicable — this component persists nothing itself;
  every operation is a stateless request.
- **Transmission**: every request travels over whatever transport the
  shared request layer uses; this component configures no
  transport-level behavior itself.
- **Retention**: not applicable — this component defines no retention
  policy of its own; retention of realm configuration, badges, levels,
  and event types is entirely the backend's concern.

