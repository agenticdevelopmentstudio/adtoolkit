
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Store (constructor argument) | diagnostic store | none (required) | This component's storage seam; MAY be shared across multiple adaptors, each tracking only its own created collections. |
| Sink (constructor argument) | diagnostic sink | none (required) | Notified of every mutation's affected URLs; production passes the host diagnostic sink. |
| Events (constructor argument) | shared event emitter | none (required) | The shared emitter behind `onDidChangeDiagnostics`; built from a window-scheduling dependency and handed to every adaptor and to the sink alike. |
| Window (to the emitter builder) | window-scheduling seam | none (required) | The debounce window scheduler; production passes a timer-backed implementation. |
| `name` (to `createDiagnosticCollection`) | string, `undefined`, or `null` | generated `_generated_diagnostic_collection_name_#<n>` when omitted | The collection's requested name; MAY collide with an existing one (see **collection-name-collision-keeps-name-uniquifies-owner**). |
| Maximum decodable array length | integer | `100,000` | The ceiling this host enforces for any decoded diagnostics array. Not settable per call. |
| `onDidChangeDiagnostics` delay | time interval | `0.050` seconds | The debounce window width; fixed, not configurable per instance. |

