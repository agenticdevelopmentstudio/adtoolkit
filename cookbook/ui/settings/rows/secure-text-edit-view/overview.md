
The Secure Text Edit View is a settings text row. Per the source's own doc
comment, it is meant for API keys, passwords, and other secrets that are
still routed through a view model — typically one whose backing setting has
secure storage enabled and is therefore stored through a keychain-backed
storage provider.

It specializes the text edit row
(adtoolkit://cookbook/ui/settings/rows/text-edit-view), overriding
exactly one thing — it constructs a masking (dot-obscured) secure field in
place of the plain field its base row would otherwise construct — so the
entry is dot-masked. The text edit row's own row layout, theme-driven
font/color styling, commit path, and view-model sync are out of this
recipe's scope; only the delta this specialization adds — the masked field
type and the ban on further specialization — is documented here. See
adtoolkit://cookbook/ui/settings/rows/text-edit-view for everything a
caller instantiating this component also gets.

