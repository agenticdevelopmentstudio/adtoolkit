
**Data source contract**

- **provider-status**: the status operation MUST return, asynchronously, the connectivity status
  (an `email`/`sms` connectivity pair) for the given ecosystem, or throw.
- **template-listing**: the template-listing operation MUST return, asynchronously, the full list
  of templates available for composing a message, or throw.
- **message-log-listing**: the log operation MUST return, asynchronously, a page of log entries
  (the requested `page`/`pageSize` plus `items` and `total`) for the given ecosystem, or throw.
- **message-send**: the send operation MUST submit the given send request and return,
  asynchronously, a send result, or throw.

**Data shapes**

- **messaging-channel-identity**: the channel type MUST expose exactly two values, `email` and
  `sms`, with a fixed `title` ("Email"/"SMS"), `providerName` ("Postmark"/"Twilio"),
  `providerLabel` (`"{title} ({providerName})"`), and an icon identifier ("envelope"/"message")
  for each value.
- **template-placeholder-scan**: a template's placeholder list MUST contain the `{{name}}`
  placeholder names found across `subject`, `htmlBody`, `textBody`, and `smsBody` (treated as
  `""` when absent) joined in that order, trimmed, de-duplicated, in first-seen order — the
  `subject` counts because a template whose only placeholder sits in its subject would otherwise
  report none and skip the send form's required-variable gate entirely.
- **log-entry-shape**: a log entry MUST expose `id`, `customerId`, `ecosystemId`, `channel`,
  `recipient`, `body`, and `status` as required fields, and `subject`, `templateId`, `providerId`,
  `errorMessage`, `sentBy`, `origin`, and `createdAt` as independently optional fields.
- **log-page-shape**: a log page MUST expose `items` (the page's list of log entries), `total`,
  `page`, and `pageSize`.
- **send-request-shape**: a send request MUST expose a required `userId` and `channel`, with
  `subject`, `body`, `templateId`, `templateVars`, and `recipient` each independently optional.
- **send-result-shape**: a send result MUST expose a required `status` string plus independently
  optional `providerId` and `error` fields.

**Copy helpers**

- **status-line-text**: the status-line text MUST be `"Provider status unavailable"` for an
  absent status, and otherwise MUST join, with `" · "`, one `"{channel.title}: connected"` or
  `"{channel.title}: not connected"` segment per channel, in `email`, `sms` order.
- **banner-text-connected**: the banner text MUST be absent when the given channel's status is
  connected.
- **banner-text-not-connected**: the banner text MUST be `"{channel.providerLabel} is not
  connected — sends on this channel will fail. Connect a {channel.providerName} integration on
  this product's Integrations tab."` when the given channel's status is not connected.
- **banner-text-unknown**: the banner text MUST be `"Couldn't check whether
  {channel.providerLabel} is connected — sends on this channel may fail."` when the status is
  absent.
- **placeholder-extraction**: the placeholder scan MUST scan the given text with a pattern
  matching two braces, a captured run of non-brace characters, then two braces again, MUST trim
  each captured name, MUST skip an empty trimmed name, and MUST return the surviving names
  de-duplicated in first-seen order.

**Navigation**

- **rail-top-level**: resolving the rail path MUST return a navigation level with two items —
  `"send"` ("Send a message", leading to a detail view) and `"log"` ("Message log", leading to a
  list) — when the path's first segment is absent, with the `"send"` item's `sublabel` set from
  the status-line text.
- **rail-status-swallowed-at-top-level**: the top-level branch MUST fetch the status operation
  without propagating its failure, so a status-operation failure MUST NOT prevent the level from
  rendering — it MUST instead produce the status-line text for an absent status ("Provider status
  unavailable") as the `"send"` item's `sublabel`.
- **rail-send-route**: a path whose first segment is `"send"` MUST resolve to the send detail
  view.
- **rail-log-route**: a path whose first segment is `"log"` MUST resolve to the log child,
  resolved with the remaining path segments.
- **rail-unknown-route-empty**: a path whose first segment is neither `"send"` nor `"log"` MUST
  resolve to no content.

**Send form**

- **send-detail-load-errors-propagate**: the send detail MUST fetch the template-listing
  operation without swallowing its failure, and a failure MUST be wrapped into the common error
  type and rethrown — never swallowed.
- **send-detail-status-swallowed**: the send detail MUST also fetch the status operation without
  propagating its failure, the same graceful-degradation rule as
  `rail-status-swallowed-at-top-level`.
- **send-form-provider-banners**: for every channel whose banner text is present, the send detail
  MUST add one read-only field, keyed `"{channel}Status"` and labeled with that channel's provider
  label, whose value is that banner text, collected into a form section titled `"Provider status"`
  inserted at the front of the form's sections — and MUST NOT insert that section when no banner
  applies.
- **send-form-default-values**: the send form's initial values MUST set `"channel"` to `"email"`
  and `"templateId"` to `""`.
- **send-form-field-order**: building the send form MUST declare, in order, an unlabeled section
  with a required `"channel"` select (options `email`, `sms`), a required `"userId"` text field
  (label "Customer ID", placeholder "customer id"), and an optional `"recipient"` text field
  (label "Recipient override"), followed by a section titled "Content" with an optional
  `"templateId"` select (label "Content", options: the freeform option plus one option per
  template), an optional `"subject"` text field (label "Subject", placeholder "Email only"), an
  optional `"body"` text-area field (label "Message body", minimum 3 lines), and an optional
  `"templateVars"` JSON field (label "Template variables").
- **send-form-required-tiers**: only `"channel"` and `"userId"` MUST be marked required at the
  field level (rejected by the shared form validator before the save action runs); `"recipient"`,
  `"subject"`, `"body"`, and `"templateId"` MUST NOT be field-level required — their conditional
  requirements are enforced inside the save action instead.
- **send-freeform-subject-required-for-email**: when no template is selected and the channel is
  email, the save action MUST fail validation with "Enter a subject." when the trimmed
  `"subject"` value is blank.
- **send-freeform-body-required**: when no template is selected, the save action MUST fail
  validation with "Enter a message body." when the trimmed `"body"` value is blank, regardless of
  channel.
- **send-freeform-subject-suppressed-for-sms**: when no template is selected and the channel is
  SMS, the save action MUST set the send request's `subject` to absent even when a `"subject"`
  value was entered.
- **send-sms-recipient-required**: when the channel is SMS, the save action MUST fail validation
  with "A recipient phone number is required for SMS." when the trimmed `"recipient"` value is
  blank, checked before any other field is validated.
- **send-template-must-exist**: when `"templateId"` is non-blank, the save action MUST fail
  validation with "Choose a template." when no template in the list the send form was built from
  has that `id`.
- **send-template-placeholder-validation**: when a template is selected, the save action MUST
  parse `"templateVars"` and MUST fail validation with `Template needs a value for "{name}".` for
  the first placeholder (in the template's placeholder-list order) whose trimmed value is blank or
  absent, checking one placeholder at a time rather than collecting every missing one in a single
  failure.
- **send-template-vars-parsing**: parsing the template variables MUST return an empty object when
  the trimmed text is blank, MUST parse a non-blank text as JSON, and MUST fail validation with
  "Template variables must be a JSON object of strings." when the parsed value is not a JSON
  object whose every value is a string.
- **send-channel-fallback-to-email**: the save action MUST resolve `"channel"` against the two
  known values and MUST fall back to email when the submitted value does not match `"email"` or
  `"sms"`.
- **send-invokes-data-source**: on successful validation, the save action MUST call the send
  operation with the assembled send request, and any thrown error MUST be wrapped into the common
  error type and rethrown.
- **send-result-failure-messaging**: when the returned send result's `status` is not `"sent"`,
  the save action MUST fail validation with the trimmed `error` message when non-blank, or the
  fixed fallback message ("Could not send — check the recipient and provider config.") otherwise.
- **freeform-option-identity**: the freeform option MUST be the select option with `value: ""`
  and `title: "Freeform message"`, and MUST be the first option in the `"templateId"` select.
- **send-form-has-no-delete-action**: building the send form MUST NOT expose a delete action.

**Message log**

- **log-fetch-errors-propagate**: resolving the log child MUST fetch the log operation with
  `page: 1, pageSize: logPageSize` without swallowing its failure, and a failure MUST be wrapped
  into the common error type and rethrown.
- **log-list-item-mapping**: when no entry id follows in the path, resolving the log child MUST
  return a navigation level mapping each log page entry to an item with `label = recipient`,
  `sublabel = "{channel.title} · {status} · {displayDate(createdAt)}"`, an icon from the channel's
  icon identifier, and leading to a detail view, with an empty-state message of "No messages sent
  yet."
- **log-page-request-shape**: every call this logic makes to the log operation MUST request
  `page: 1` and `pageSize: logPageSize` (100).
- **log-pagination**: resolving the log child always requests `page: 1` and never reads the log
  page's `total` or requests `page: 2` or later, although the decoded wire shape (`total`, `page`,
  `pageSize`) carries what a paged view needs. The log shows at most the newest `logPageSize`
  (100) sent messages, with no indication that older entries exist.
- **log-entry-lookup**: when an entry id follows in the path, resolving the log child MUST return
  no content when no entry in the fetched page has that `id`, and otherwise MUST return a detail
  view for the matching log entry.
- **log-entry-detail-fields**: the entry detail MUST present, in order, read-only `"channel"`
  (`channel.title`), `"recipient"` (monospaced), `"subject"` (the trimmed subject or `"—"`), and
  `"status"` fields, then an `"error"` field only when `errorMessage` is non-blank, then `"body"`
  and `"sent"` (the formatted `createdAt`) — and MUST NOT present `sentBy`, `origin`,
  `templateId`, or `providerId` even though a log entry carries them.
- **log-entry-detail-identity**: the entry detail's `id` MUST be `"messaging-log-entry:{entry.id}"`
  and its `title` MUST be the trimmed `subject` or `"Message"` when blank.
- **log-entry-detail-has-no-actions**: the log entry detail MUST expose neither a save action nor
  a delete action — it is read-only.

