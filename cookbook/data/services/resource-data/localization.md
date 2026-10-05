
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `resourceItem.loadFailedFallback` | Failed to load. | The resource-item read state's returned error message when the underlying failure is not an error instance |
| `resourceList.loadFailedFallback` | Failed to load. | The resource-list read state's returned error message when the underlying failure is not an error instance |

Both occurrences are the same hardcoded English literal, with no lookup
table, message-catalog entry, or locale parameter anywhere in this
component — there is no localization mechanism in this component at all.
This is a plain fact about the source, not a gap: a port to a platform with
a localization layer MUST decide, as a design choice outside this contract,
whether and how to route this string through it.

