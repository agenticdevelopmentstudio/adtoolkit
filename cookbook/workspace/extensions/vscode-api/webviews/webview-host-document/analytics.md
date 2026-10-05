
Not applicable: no file in this component emits a client-side analytics or
telemetry event. The `postMessage`/`setState` traffic the generated
bootstrap sends through `agenticWebview` is the bridge's own protocol
traffic, addressed to the native host, not analytics instrumentation.

