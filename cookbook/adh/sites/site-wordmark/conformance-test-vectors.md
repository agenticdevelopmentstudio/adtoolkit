
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-registry-brand, accent-trailing-word | Site identifier `"research"` | Renders `Agentic Developer` + a gold-italic `Research`; full text reads "Agentic Developer Research" |
| T2 | default-identity-to-description | Site identifier `"research"` (no tagline) | Identity line reads "Store & review research" (the registry description) |
| T3 | honor-explicit-tagline | Site identifier `"research"`, tagline `"Published research"` | Identity line reads "Published research" |
| T4 | omit-identity-when-null | Site identifier `"research"`, tagline explicitly null | No identity line is rendered |
| T5 | fall-back-on-unknown-site | An unknown site identifier `"not-a-real-site"` | No lead segment; renders `not-a-real-site` as the accent; no identity line; does not throw |
| T6 | accent-trailing-word | Site identifier `"bitbag"` | Full label "Bitbag" does not start with "Agentic Developer "; no lead segment, whole label "Bitbag" is the accent; identity line reads "The Agentic Developer persona" |
| T7 | omit-identity-when-null | Site identifier `"research"`, tagline as empty string | No identity line is rendered (empty string is falsy, same as null) |

