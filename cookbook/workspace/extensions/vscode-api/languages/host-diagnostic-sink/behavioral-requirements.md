
- **protocol-conformance**: This component MUST conform to the diagnostic-sink protocol, whose only requirement is a `diagnosticsChanged(for:)` operation taking a list of URLs.
- **type-is-final**: This component MUST NOT be designed for subclassing.
- **emitter-required-no-default**: The sink's constructor MUST take the shared emitter as a required parameter with no default value, matching the diagnostics bridge's own required constructor parameters.
- **emitter-stored-once**: This component MUST store the constructor's emitter argument in a property set exactly once at initialization and never reassigned.
- **log-before-fire**: `diagnosticsChanged(for:)` MUST log, recording the count of URLs, before it fires the emitter.
- **fire-forwards-uris-unchanged**: `diagnosticsChanged(for:)` MUST fire the emitter with the exact list it was given, in the same order, without deduplicating, filtering, copying, or transforming any element.
- **fire-called-unconditionally**: `diagnosticsChanged(for:)` MUST fire the emitter exactly once per call, with no guard on the list's count; it MUST fire even when the list is empty.
- **one-emitter-shared-across-adaptors**: The emitter instance passed to the sink's constructor MUST be the same instance passed to every diagnostics-bridge instance constructed for the same extension host; the extension host's own installer MUST construct exactly one such emitter and share it between the two.
- **loggable-conformance**: This component MUST conform to the shared logging convention, giving it the host application's own subsystem and a category named after this component, per that convention's own defaults.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

