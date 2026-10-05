
Subsystem: the host's own logging subsystem | Category: this adaptor's own category

| Event | Level | Message |
|-------|-------|---------|
| `createWebviewPanel` presented against no open window | error | `<extension> asked for a webview panel of type <viewType>, but there is no window to put it in` |
| A presented panel could not be given a script object | error | `A panel of view type <viewType> for <extension> could not be given a script object; it was closed again` |
| A restored panel or contributed view could not be given a script object | error | `A restored panel of view type <viewType> could not be given a script object; it stays blank` / `The contributed view <viewID> could not be given a script object; it stays empty` |
| A hand-over panel was already closed | notice | `The <kind> <identifier> was closed before <extension> could fill it; it is not handed over` |
| A second serializer or provider registered under the same key | error | `<extension> registered a second webview panel serializer for view type <viewType>; the later one wins` / the provider equivalent |
| A registered serializer or provider has no callable method to invoke | error | `<extension> has a serializer for view type <viewType> but no deserializeWebviewPanel to call` / the provider equivalent |
| `deserializeWebviewPanel` or `resolveWebviewView` threw | error | `<extension>'s deserializeWebviewPanel threw for view type <viewType>: <reason>` / the `resolveWebviewView` equivalent |
| `deserializeWebviewPanel` or `resolveWebviewView` could not be dispatched | error | `<extension>'s deserializeWebviewPanel could not be invoked for view type <viewType>` / the `resolveWebviewView` equivalent |

No other event in this file is logged: every `createWebviewPanel`, `registerWebviewPanelSerializer`, and `registerWebviewViewProvider` argument-validation refusal is surfaced directly to the extension as a raised exception instead of being logged, per the corresponding Behavioral Requirements above.

