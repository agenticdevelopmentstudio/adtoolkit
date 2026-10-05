
- This component introduces one semantic element of its own — the loading text —
  and otherwise delegates all interactive/semantic markup to the list-with-details
  layout (a toolbar role plus its accessible name, per its own recipe), the
  send-invitation modal, and the add-users modal.
- **passes-required-aria-label** (Behavioral Requirements) is this component's one
  direct accessibility contribution: the accessible name is a required setting on
  the list-with-details layout, so each pane is forced to supply a real,
  human-readable name ("Invitation requests" / "Pending users" / "Sent invites")
  rather than omitting it.
- Toolbar action labels this component defines are all plain-text strings ("Admin
  notes", "Send invitation", "Add users"), not icon-only, so they read correctly
  through the list-with-details layout's labeling.
- The swap between the loading text and the populated list-with-details layout
  carries no live-region announcement in this component; a screen reader is
  notified of the change only insofar as its own virtual-cursor behavior picks up
  the content replacement.
- Minimum tap target: Not applicable to this component directly — traced. No
  tappable element originates here; the toolbar buttons, row selection, and modal
  controls are each the list-with-details layout's, the send-invitation modal's,
  or the add-users modal's own tap-target contract.

