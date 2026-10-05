
This logic contains no localization mechanism (no localized-string API, no string-catalog file,
no localization lookup) — every user-facing string below is a hardcoded English literal, stated
here as fact rather than as a gap:

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| — | `Provider status unavailable` | The status-line text's fallback for an absent status |
| — | `{Email/SMS} ({Postmark/Twilio})` | The channel type's `providerLabel`, built from its hardcoded titles and provider names |
| — | `{providerLabel} is not connected — sends on this channel will fail. Connect a {providerName} integration on this product's Integrations tab.` | The banner text's not-connected message |
| — | `Couldn't check whether {providerLabel} is connected — sends on this channel may fail.` | The banner text's unknown-status message |
| — | `Send email or SMS to this product's users and review what went out.` | This topic's rail-entry description |
| — | `A recipient phone number is required for SMS.` | SMS recipient-required validation |
| — | `Choose a template.` | Unknown-template-id validation |
| — | `Template needs a value for "{name}".` | Missing-placeholder validation |
| — | `Enter a subject.` | Freeform-email subject-required validation |
| — | `Enter a message body.` | Freeform body-required validation |
| — | `Template variables must be a JSON object of strings.` | The template-variables parse-shape validation |
| — | `Could not send — check the recipient and provider config.` | The fixed send-failure fallback message |
| — | `No messages sent yet.` | The log level's empty-state message |
| — | `Freeform message` | The freeform option's title |

(This is a representative sample, not the full set of literals — every one follows the same
pattern: a plain string with no key, no catalog entry, and no pluralization rule beyond ad hoc
string interpolation.)

