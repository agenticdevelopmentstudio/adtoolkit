
Logged through the shared extension-host logger, under this component's own category, at the levels below.

| Event | Level | Message |
|-------|-------|---------|
| Building a matched model's returned object fails, inside resolving `selectChatModels` | error | Names the dropped model; the model is excluded from the resolved array rather than failing the call. |
| A second `next()` call displaces an outstanding waiter on the same cursor | error | Names the one-outstanding-`next()` constraint being violated. |
| A buffered part fails to bridge into a value on the `stream` cursor | error | Names the bridging failure that becomes a bridging-failure error. |
| A tool-call part's arguments fail to parse as JSON | error | Names the malformed payload; the part is still delivered with `input: null`. |

No other event in this component is logged: a rejected `selectChatModels`/`sendRequest` call and a raised `onDidChangeChatModels` exception are each surfaced to the caller directly, per **select-chat-models-torn-down-response**, **send-request-torn-down-response**, and **on-did-change-chat-models-torn-down-response**, rather than logged.

