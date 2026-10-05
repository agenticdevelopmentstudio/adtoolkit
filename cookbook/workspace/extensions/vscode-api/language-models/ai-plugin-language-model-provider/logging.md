
Subsystem: the host's own logging subsystem | Category: this provider's own category

| Event | Level | Message |
|-------|-------|---------|
| An extension calls streaming a response with a present justification | info | `extension <extensionIdentifier> requested a language model, justification: <justification>` — the extension identifier is logged in the clear, the justification is logged redacted |

No other event in this file is logged: neither the unknown-model error nor the plugin-unavailable error is logged at the point it is thrown — both are facts the code surfaces to the caller as thrown errors instead, per **plugin-resolution-failure** and **model-id-parse-failure**/**model-id-unknown-configuration**.

