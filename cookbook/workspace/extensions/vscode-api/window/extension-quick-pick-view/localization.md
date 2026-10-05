
Not applicable: every user-visible string this component renders — the
title, the placeholder, and each item's label/description/detail — comes
from the caller-supplied `ExtensionQuickPickRequest`/`ExtensionQuickPickItem`
(originating from the VS Code extension that called `showQuickPick`), not
from a static string owned by this component. The only literal strings in
this component are the two accessibility
identifiers (`extension-quick-pick.search-field`,
`extension-quick-pick.table`) and the checkbox's own empty title, none of
which is user-facing text requiring localization.

