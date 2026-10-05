
This is the logic stack that speaks the Language Server Protocol on behalf
of the app: eight dependency-free components. It has no UI of its own. The
server session owns one language server subprocess end to end — spawn,
`initialize` handshake, request/notify, graceful-then-forced shutdown. The
registry reconciles a desired set of server configurations (a built-in
SourceKit-LSP configuration plus user configurations) against the sessions
actually running, replacing or retiring them as configurations, secrets, or
enablement change. The document-sync pipeline holds one ordered event queue
per session that forwards `textDocument/didOpen|didChange|didSave|didClose`
according to the server's negotiated sync capability. The sync coordinator
wires the document store to the registry's sessions, scopes documents to the
workspace root, and replays already-open documents to newly connected
sessions. The diagnostics store consumes each session's published-diagnostics
stream and holds the latest diagnostics per document URI. The transport
channel bridges a subprocess's raw input/output onto the JSON-RPC framing the
protocol runs over. A server configuration and the persisted settings
describe how a server is launched and where its non-secret settings and its
secrets are stored.

