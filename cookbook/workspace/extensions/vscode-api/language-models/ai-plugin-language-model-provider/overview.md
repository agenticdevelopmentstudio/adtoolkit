
This is the production language-model provider for the VS Code
extension-host seam: it offers extensions the chat models the user has
already configured in the app's own LLM Providers settings, and streams a
`sendRequest` call through the same underlying plugin path the app's own
chat surface uses. It adds no transport, no credential handling, and no
request shaping of its own — it reuses the provider-configuration/
resolver layer (which already joins a configuration to its plugin
template, stored credentials, and model) and the plugin-manager/transport
layer (which already loads a plugin and drives its request) rather than
opening a second route to a provider. Listing available chat models lists
the cross product of every model of every configuration the user has
saved — not the app's own single selected chat configuration — because
`vscode.lm.selectChatModels` asks what the host *has* and does its own
selector matching one layer above this provider. Streaming a response
turns a chat-model descriptor id of the form `"<configuration UUID>/
<model>"` back into a configuration and a model name, resolves the
configuration to a loadable plugin, builds a chat context, and adapts the
plugin transport's stream of events into the seam's own response-part
stream.

