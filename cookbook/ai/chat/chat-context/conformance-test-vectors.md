
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-chat-context-001 | context-max-tokens-default | A chat context constructed with an empty message list, model `"m"`, and an empty-valued plugin configuration, with `maxTokens` omitted | `maxTokens` reads `4096` |
| ai-chat-context-002 | context-tools-default-empty | Same construction as 001, with `tools` omitted | `tools` reads empty |
| ai-chat-context-003 | context-system-prompt-optional | Same construction as 001, with `systemPrompt` omitted | `systemPrompt` reads absent |
| ai-chat-context-004 | message-tool-fields-optional | A chat message constructed with role `user` and content `"hi"`, with no other arguments given | `toolUseId`, `toolName`, `toolArgumentsJSON`, and `toolIsError` all read absent |
| ai-chat-context-005 | message-role | The serialized form of the `toolUse` and `toolResult` roles | `"tool_use"` and `"tool_result"` respectively |
| ai-chat-context-006 | config-value-storage, config-conventional-accessors | A plugin configuration built from `{"apiKey": "k", "baseURL": "https://h", "model": "m", "extra": "x"}` (traced to `AIPluginKitTests.configAccessors`) | `apiKey` reads `"k"`, `baseURL` reads `"https://h"`, `model` reads `"m"`, the `"extra"` key reads `"x"`, and a `"missing"` key reads absent |
| ai-chat-context-007 | tool-spec-equality | Two tool specifications with identical `name`, `description`, and `parametersJSONSchema` bytes, versus a third with the same `name`/`description` but different `parametersJSONSchema` bytes | The first two compare equal; the third compares unequal to either |
| ai-chat-context-008 | context-config-required, context-model-required, no-error-domain | A minimal test plugin's request-building step, given a chat context with one user message `"hi"`, model `"test-model"`, and a plugin configuration holding only `apiKey: "secret"` (traced to `AIPluginKitTests.pluginBuildsRequest`) | The resulting request description carries `"secret"` under an `x-api-key` header and a body equal to the literal text `"test-model"`, demonstrating `model` and the configuration's `apiKey` reach the plugin unchanged |

