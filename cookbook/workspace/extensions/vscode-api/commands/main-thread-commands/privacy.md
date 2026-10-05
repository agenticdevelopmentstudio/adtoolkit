
- **Data collected**: this adaptor collects no data of its own; the ownership record holds, for the lifetime of each registration, the extension-supplied callback (and, indirectly through it, everything the extension's own module graph captured). Arguments and results that pass through `executeCommand` are the caller's own values, forwarded untouched — never copied, stored, or inspected beyond the type checks the Behavioral Requirements describe.
- **Storage**: this adaptor performs no storage of its own; the ownership record is in-memory only and exists for the adaptor's lifetime. The shared registry's own bookkeeping is likewise in-memory, out of this component's scope.
- **Transmission**: nothing here leaves the process; every call is an in-process round trip between the host and the script engine the same process owns.
- **Retention**: a registered callback (and the context it keeps alive) is retained in the ownership record until its disposable is disposed, until the adaptor is torn down, or until the shared registry replaces it under the same id — per **disposable-is-idempotent** and **dispose-unregisters-every-owned-command**.

