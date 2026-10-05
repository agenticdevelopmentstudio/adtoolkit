
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Error message: `request body too large` | Hardcoded en | HTTP 413 response when body exceeds MAX_BODY_BYTES |
| Error message: `Internal Server Error` | Hardcoded en | HTTP 500 response when an unhandled non-HTTP error occurs |
| Cycle timeout error log | `cycle exceeded {{cycleTimeoutMs}}ms — abandoning it and releasing the scheduler (self-heal)` | Console error when watchdog fires |
| Cycle failure error log | `cycle failed: {{error}}` | Console error when cycle throws |

