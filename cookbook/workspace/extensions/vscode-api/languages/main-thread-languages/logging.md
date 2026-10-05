
Subsystem: this host's own bundle identifier, falling back to a placeholder when absent | Category: this component's own name

| Event | Level | Message |
|-------|-------|---------|
| A `wordPattern`'s `pattern` fails to compile under the platform's regex engine | error | `wordPattern '/pattern/flags' does not compile under the platform's regex engine (<error>); stored unvalidated rather than refused, per Ruling 12` |

No other event in this file is logged: a non-string `languageId`, an empty-match `wordPattern` refusal, and a torn-down adaptor's answer are each surfaced to the caller directly (as a thrown JS error or a rejected promise) rather than logged, per **set-language-configuration-requires-string-id**, **word-pattern-empty-match-refusal**, **get-languages-rejects-when-torn-down**, and **set-language-configuration-raises-when-torn-down**.

