
This component makes no logging call of its own — no console output and no structured logger. Every failure it produces surfaces exclusively as a rejected promise to its caller (see Behavioral Requirements and Localization); it is the caller's responsibility to log or alert on that rejection.

| Event | Level | Message |
|-------|-------|---------|
| n/a | n/a | This component emits no log output at any level. |

