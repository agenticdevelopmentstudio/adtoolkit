
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `textDelta` payload | string | none (required) | The stream event's chunk of assistant text for this event. |
| `toolUse.id` | string | none (required) | The stream event's identifier for one model-requested tool call. |
| `toolUse.name` | string | none (required) | The stream event's name of the tool the model wants to call. |
| `toolUse.argumentsJSON` | raw bytes | none (required) | The stream event's raw, undecoded JSON arguments for the call. |
| `end.stopReason` | optional string | absent | The stream event's provider-supplied reason the stream ended, or absent. |
| `name` | string | none (required) | The tool definition's tool name advertised to the model. |
| `description` | string | none (required) | The tool definition's tool description advertised to the model. |
| `parametersJSONSchema` | raw bytes | none (required) | The tool definition's opaque JSON Schema bytes for the tool's parameters. |
| `toolUseId` | string | none (required) | The tool result's identifier correlating this outcome with its originating tool-use call. |
| `content` | string | none (required) | The tool result's result text, or error text, from running the tool. |
| `isError` | boolean | none (required) | The tool result's flag marking whether the tool call failed. |

These three shapes define no environment variable and no settings key of
their own — every value arrives as an associated value on a stream-event
case, or as a parameter given when constructing a tool definition or tool
result.

