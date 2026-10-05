
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| The resource-cache retention constant | exported constant | `1,800,000` ms (30 min) | Retention time every query entry under a long-retention key prefix uses, pinned by the cache-client factory |
| The long-retention key prefixes | list of cache-key prefixes, fixed in the cache-client factory | `resource-list`, `resource-item` | The key prefixes whose entries are pinned to the retention constant; these are the keys the resource-data component writes, and a host with different resource key names changes this list rather than the requirement |
| The default staleness window | hardcoded in the cache-client factory | `300,000` ms (5 min) | Client-wide default staleness for every query built on this client |
| The default retry count | hardcoded in the cache-client factory | `1` | Client-wide default retry count for every query built on this client |
| The mounted subtree | required prop of the cache provider component | none (required) | Subtree the provider mounts its underlying cache-provider wrapper around |

None of these values is exposed through a caller-facing setter (no
configuration function exists in this component, unlike the resource-data
recipe's own configuration entry point); changing any of them requires
editing the source module itself.

