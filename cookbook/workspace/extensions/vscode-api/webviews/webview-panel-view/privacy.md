
- **Data collected**: The rendered page's own state, whatever it last passed to `setState`, carried as opaque JSON text; this component does not interpret it or add data of its own.
- **Storage**: None persisted by this component. The page state is held only in memory for the life of this instance; the webview's non-persistent data store means its own cookies, local storage, and cache do not survive the app quitting. Whatever survives an app restart is entirely the responsibility of a separate serializer that reads this panel's restoration snapshot, out of this component's scope.
- **Transmission**: None over a network by this component directly. The rendered page may make its own network requests as part of the extension's content, out of scope here. Locally, messages cross the webview/host boundary through the message handler and its script-invocation channel, never leaving the device.
- **Retention**: The page state lives exactly as long as this component's instance does; disposing the panel clears the webview's content but does not clear the page state itself.

