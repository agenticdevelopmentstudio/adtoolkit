
Not applicable — this is a presenter contract and its two associated data types, not a visual component. The per-item lifecycle a conformer must honor (never shown, shown, hidden, disposed) is captured under Behavioral Requirements as call-ordering rules rather than as a visual-state table, because the state itself — `isVisible`/`isDisposed` — is tracked by the caller's own model, not by this component.

