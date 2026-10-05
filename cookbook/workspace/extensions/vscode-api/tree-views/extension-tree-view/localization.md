
Not applicable: every string this component displays — the message banner, the row label, the row caption, the row tooltip, and the resolved pane title — comes from the extension's own data (the data source's message and title; the tree item's label, description and tooltip; the contributed view's name), not from an app string catalog, so this component owns no localization keys of its own. The one literal string in this component (`"A tree provider did not answer getChildren in time; the branch stays unread"`) is a diagnostic log message, not user-facing text — see Logging.

