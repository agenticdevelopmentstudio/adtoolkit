
Not applicable: every user-facing string this component surfaces — title,
prompt, placeholder, value, and validation message — is passed in at
runtime from `model.request`/`showValidation(_:)`'s parameter, i.e. text
the requesting extension itself already chose in whatever locale it
targets. This component defines no user-facing string literal of its own
to localize.

