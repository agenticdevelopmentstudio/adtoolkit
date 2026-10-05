
- **Null/empty input**: Constructing with no descriptor MUST use a
  default descriptor rather than leaving the descriptor unset or crashing
  (**defaults-descriptor-when-omitted**); that default descriptor's title
  is the empty string, so the sidebar title is set to `""` — this
  component performs no validation that a title is non-empty.
- **Boundary values**: The detail-pane minimum-thickness floor of `200`
  and the content-sized-sidebar flag of true are fixed override values,
  not caller-supplied inputs, so there is no boundary range to exercise on
  them directly; the only defined relationship is that `200` MUST stay
  below the inherited settings split view's default floor of `400` points
  (see Design Decisions).
- **Concurrent access**: Not applicable — the component's construction and
  every property access are confined to a single, serialized execution
  context (see Platform Notes), so there is no concurrent-access surface
  for this component to define behavior for.
- **Error states**: Not applicable — every member in this component (both
  construction paths and the four computed properties) is synchronous and
  non-throwing; no dependency, network call, or fallible operation exists
  in this component.
- **Offline/disconnected state**: Not applicable — this component performs
  no networking and has no dependency on connectivity.
- **Help chain resolves to no help at all**: When there is no inner
  selection and no subclass override of help content, effective help
  content evaluates to none (**surfaces-empty-help-when-chain-exhausted**,
  composing **falls-back-help-content-through-inner-selection**); this is
  a defined state — the outer split's help drawer shows its own empty
  state rather than hiding its help affordance.
- **The descriptor's disabled flag and section field go unused by this
  component**: The descriptor type carries both fields, but neither is
  read anywhere in this component; this is not a gap in this component —
  both are consumed by the sidebar-row renderer (the panel list) and by
  the settings split view's section-sort logic, outside this component.
  This component simply has no code path that reads either field.

