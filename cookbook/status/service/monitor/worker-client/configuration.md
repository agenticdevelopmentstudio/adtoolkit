
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| cycle timeout (constructor parameter) | a duration in milliseconds | none — caller-supplied, required | How long one cycle run waits for a cycle-reply before the pending promise rejects and the worker is terminated (cycle-timeout-rejection-message, timeout-terminates-and-clears-worker). Not validated or clamped by this component — see Edge Cases › Boundary values. |
| connection value (constructor parameter, part of worker data) | an opaque connection type | none — caller-supplied, required | Forwarded unchanged into every spawned worker's data. This component never inspects or opens it; the worker itself is what validates and opens it. |
| status configuration (constructor parameter, part of worker data) | a status configuration record | none — caller-supplied, required | Forwarded unchanged into every spawned worker's data. See Privacy for the credential/secret fields it carries. |
| cooldowns (spawn-added worker-data field) | a shared cooldown-state buffer | current value of the shared cooldown-state buffer (a process-wide singleton) | Added by the spawn step itself on every call; never read from the caller-supplied worker data — see cooldowns-attached-at-spawn. |
| Worker entry module | fixed identifier | resolved via the host package's own published-exports mechanism | Not configurable by the caller; hardcoded inside the spawn step — see worker-entry-via-package-exports. |

