
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `messages` | list of chat messages | none (required) | The chat context's conversation history for the turn, in caller-supplied order. |
| `model` | string | none (required) | The chat context's chosen model identifier, forwarded to the plugin. |
| `systemPrompt` | optional string | absent | The chat context's optional system prompt. |
| `maxTokens` | whole number | `4096` | The chat context's token budget for the response; unvalidated (see Edge Cases). |
| `tools` | list of tool specifications | empty | The chat context's tools the host wants exposed to the model for this turn. |
| `config` | plugin configuration value | none (required) | The chat context's resolved, host-supplied configuration values (including any secret). |
| `role` | role value | none (required) | The chat message's speaker/kind: `system`, `user`, `assistant`, `toolUse`, or `toolResult`. |
| `content` | string | none (required) | The chat message's text content. |
| `toolUseId` | optional string | absent | The chat message's identifier correlating a tool call with its result. |
| `toolName` | optional string | absent | The chat message's tool name, when the message represents a tool call or result. |
| `toolArgumentsJSON` | optional raw bytes | absent | The chat message's raw JSON arguments for a tool call. |
| `toolIsError` | optional boolean | absent | The chat message's flag marking a tool result as an error. |
| `name` | string | none (required) | The tool specification's tool name. |
| `description` | string | none (required) | The tool specification's tool description. |
| `parametersJSONSchema` | raw bytes | none (required) | The tool specification's raw JSON Schema bytes for the tool's parameters. |
| `values` | string-keyed dictionary of strings | none (required) | The plugin configuration's resolved key/value bag, conventionally including `apiKey`, `baseURL`, and `model`. |

