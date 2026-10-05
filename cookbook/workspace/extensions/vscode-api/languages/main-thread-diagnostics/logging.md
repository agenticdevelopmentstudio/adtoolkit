
Subsystem: this host's bundle identifier, falling back to `"nil"` | Category: the shared category declared once for every extension-bridge component, including this one

| Event | Level | Message |
|-------|-------|---------|
| An array passed for decoding reports a length over 100,000 | error | (logged inside the shared array-length helper, not inside this component): `refusing an array of <count> elements: longer than the 100000 this host decodes` |

No other event in this component is logged: this component itself contains no direct debug/error log call. The shared raise-an-exception helper — which every raised message above goes through — logs only in the extremely rare case that building the exception value itself fails, not on the ordinary path of raising a message; every other decode failure surfaces to the caller as a thrown exception or an absent return rather than a log line. The host diagnostic sink's own report-a-change step (not part of this component's given source) logs its own "diagnostics changed for <count> uri(s)" debug line on every mutation this component reports to it; that log site belongs to the sink, not to this component.

