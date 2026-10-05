
The serializer's labels are hardcoded English and this logic has no localization layer. The copied text is meant for pasting into an LLM, and the labels are part of that format.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; hardcoded) | `endpoint` | Label for the row title |
| (none; hardcoded) | `url` | Label for the title URL |
| (none; hardcoded) | `environment` | Label for the environment |
| (none; hardcoded) | `platform` | Label for the platform phrase |
| (none; hardcoded) | `problem` | Label for the problem text |
| (none; hardcoded) | `http status` | Label for the last probe's HTTP status |
| (none; hardcoded) | `response` | Label for the last probe's latency |
| (none; hardcoded) | `branch` | Label for the deploy branch |
| (none; hardcoded) | `since` | Label for the onset time |
| (none; hardcoded) | `last check` | Label for the last probe time |
| (none; hardcoded) | `commit` | Label for the SHA and subject |
| (none; hardcoded) | `commit url` | Label for the commit URL |
| (none; hardcoded) | `link` | Label for the provider dashboard or logs link |
| (none; hardcoded) | `error:` | Header line of the error block |
| (none; hardcoded) | `{statusWord} on {platform}` | Platform phrase, for example `built on vercel` |

