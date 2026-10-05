
This is the "Danger Zone" section that closes an entity's own settings pane (every
focused-topic-detail route reuses it). It is a disclosure that is **collapsed and neutral
by default**, so a settings pane does not shout its most destructive action; the red accent
appears **only once the section is disclosed**, keeping least-astonishment for the closed
state.

Once open, the section reveals a description of what the delete cascades through and
a destructive Delete button. Deleting is gated behind a **two-phase confirm dialog**:

1. **Acknowledge** — "Delete {entity}?" states that the delete removes all the
   entity's data (including the named `childEntities`) and asks "Do you wish to
   proceed?" (Cancel / Yes).
2. **Type-to-confirm** — the user must type the entity's exact identifier
   (`confirmValue`, the entity's unique identifier) into an input; the "Permanently Delete" button enables
   **only** on an exact, case-sensitive, untrimmed match before the delete runs.

While the delete is in flight the dialog cannot be dismissed, and a thrown error
surfaces inline without closing the dialog. It composes a disclosure, a button, and a
dialog, plus the shared text-input and label primitives.

