
The headline operation returns hardcoded, uppercase English strings with no localization layer: `"ALL SYSTEMS OPERATIONAL"`, `"1 SERVICE NEEDS ATTENTION"`, `"{count} SERVICES NEED ATTENTION"`, `"1 PROBLEM"`, `"{count} PROBLEMS"`. Pluralization is a binary count-equals-one test. The activity-window-caption operation returns the English unit suffixes `h` and `d`.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `ALL SYSTEMS OPERATIONAL` | Headline when state is ok |
| (none; literal) | `1 SERVICE NEEDS ATTENTION` | Headline, warn, one problem |
| (none; literal) | `{count} SERVICES NEED ATTENTION` | Headline, warn, other counts |
| (none; literal) | `1 PROBLEM` | Headline, down, one problem |
| (none; literal) | `{count} PROBLEMS` | Headline, down, other counts |
| (none; literal) | `{n}h` / `{n}d` | Activity window caption |

