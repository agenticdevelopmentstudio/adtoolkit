
Not applicable: this file emits no analytics or usage-telemetry event describing its own execution. `collectTelemetry`, reached only indirectly through `runMonitorCycle`, polls GlitchTip/PostHog for data about the *monitored* fleet — it is not this file instrumenting itself.

