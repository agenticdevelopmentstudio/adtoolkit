
- **Data collected**: this component collects no data of its own; it decodes and re-encodes whatever `range`, `message`, `severity`, `source`, `code`, `relatedInformation`, and `tags` values an extension or the host already holds, without retaining a copy beyond the return value of each call.
- **Storage**: this component performs no storage of its own; a decoded diagnostic value is only as persistent as whatever the caller does with the returned value.
- **Transmission**: this component makes no network call; it neither sends nor receives anything over a network.
- **Retention**: nothing in this component is retained beyond the lifetime of one operation's local variables, except the per-context installed-class cache (`__vscodeDiagnosticTypesClasses`), which holds only class/prototype objects, never a diagnostic's data.

