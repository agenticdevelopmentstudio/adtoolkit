
Not applicable: this file collects, stores, or transmits no credential or user data of any kind — it retains only an in-memory failure-tracking map keyed by check `id` (a fixed provider name) holding a run count and a millisecond timestamp, and it passes through or rewraps each check's own `label`/`detail` text without ever inspecting it for sensitive content; any credential a check's `detail` might incidentally reference originates and is handled entirely outside this file, in the calling package's own provider checks.

