
None of the 8 parts use a runtime string-table or localized-bundle lookup — every user-facing string below is a hardcoded English literal.

| Source | String(s) |
|--------|-----------|
| provider identity's display names | `"Claude Code CLI"`, `"Anthropic (Claude)"`, `"OpenAI (ChatGPT)"`, `"Google (Gemini)"`, `"Custom (OpenAI-compatible)"` |
| provider identity's recommendation notes | `"Uses your existing Claude Code login — no API key needed"`, `"Haiku 4.5 — fast and inexpensive (~$0.80/M input tokens)"`, `"GPT-4.1 Nano — cheapest OpenAI model (~$0.10/M input tokens)"`, `"Gemini 2.0 Flash — fast, free tier available"` |
| provider identity's API-key placeholders | `"sk-ant-..."`, `"sk-..."`, `"AIza..."`, `"API key"` |
| request error descriptions | `"Invalid server response"`, `"Custom base URL is required"`, `"This provider does not use HTTP requests"` |
| reply/error parsing fallbacks | `"(Unable to parse response)"`, `"(Empty response)"`, `"HTTP \(statusCode)"` |
| CLI error descriptions | `"Claude CLI not found (install Claude Code or check your PATH)"`, `"Failed to launch claude: \(message)"`, `"claude -p failed: ..."`, `"Empty reply from claude -p"` |

