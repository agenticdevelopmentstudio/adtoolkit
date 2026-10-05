
Not applicable: this component emits no analytics event; it returns a list of file locations, a string, or a decoded/encoded value to its caller and performs no telemetry of its own. (An extension's use of the two unbuilt fields this component excludes, `enableCommandUris` and `portMapping`, is recorded by the shared not-implemented ledger — but that recording happens in the webviews bridge adaptor, a different component, before a value of this component is ever constructed.)

