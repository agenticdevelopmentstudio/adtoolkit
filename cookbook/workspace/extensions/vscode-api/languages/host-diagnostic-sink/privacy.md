
- **Data collected**: this component collects no data of its own; `diagnosticsChanged(for:)` receives whatever list of URLs the diagnostics bridge's mutating operations already computed as affected and forwards them unchanged to the emitter. The only thing it derives independently is a count, which is what it logs — not the URLs themselves.
- **Storage**: none; this component holds no state beyond its own emitter reference and performs no persistence.
- **Transmission**: nothing leaves the process; firing the emitter hands the list to the shared event emitter, which delivers it to a script context already running in the same process — see the `extension-host-vs-code-api-extension-event` ingredient.
- **Retention**: none; this component keeps no copy of the list after `diagnosticsChanged(for:)` returns.

