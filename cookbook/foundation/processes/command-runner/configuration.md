
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| process (parameter to the run-to-completion operation) | opaque process handle | none — required | The already-configured process to run; its standard output and standard error are overwritten with this component's own pipes. |
| timeout (parameter to the run-to-completion operation) | number (seconds) | none — required | How long the run is given before it is terminated and reported as timed out. |
| watchdog (parameter to the run-to-completion operation) | optional watchdog value | none | An optional condition, polled while the process runs, that ends the run early for a reason other than the clock. |
| interval (watchdog parameter) | number (seconds) | none — required | How often the abort condition is polled; the run ends within one interval of the condition becoming true. |
| abort condition (watchdog parameter) | callback returning true/false | none — required | Called on the waiting thread, never concurrently with itself; the first true ends the run. |

The fixed grace period (2 seconds — the wait between the graceful and forceful termination signals, and the bound on the post-exit drain wait) is a private, fixed constant; it is not exposed as a parameter, environment variable, or settings key anywhere.

