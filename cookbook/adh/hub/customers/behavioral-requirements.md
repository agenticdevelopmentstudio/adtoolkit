
### CustomersDataSource.swift — server data-access contract

- **data-source-contract**: the customers data source MUST be an asynchronous, fallible interface
  declaring five operations: `list(ecosystemID:)`, `get(id:)`, `create(_:)`, `update(id:_:)`, and
  `delete(id:)`.
- **list-is-ecosystem-scoped**: `list(ecosystemID:)` MUST take an
  `ecosystemID` parameter; `create(_:)` instead carries the scope inside
  its `CustomerInput` payload's own `ecosystemId` field (see
  `customer-input-shape`).
- **get-update-delete-take-no-ecosystem-parameter**: `get(id:)`,
  `update(id:_:)`, and `delete(id:)` MUST each take only a bare
  `id: String` (plus, for `update`, a `CustomerInput`), with no
  `ecosystemID` parameter of their own — unlike `list(ecosystemID:)` and
  unlike `create(_:)`'s payload, none of these three operations names or
  carries the ecosystem it is scoped to at the protocol level (see
  `customer-lookup-not-ecosystem-scoped`).
- **data-source-is-reference-semantics**: an implementation of the customers data source MUST have
  reference semantics (a shared, stateful client), never be a copied value; none of the given
  sources supplies a concrete implementation.

### CustomersModels.swift — data shapes

- **customer-shape**: a customer MUST be a serializable, comparable, identifiable value exposing
  `id` and `ecosystemId` strings and seven optional string fields — `email`, `displayName`,
  `externalId`, `slug`, `avatarUrl`, `createdAt`, `updatedAt` — with no custom decoding or
  encoding, per the source's own doc comment "Every descriptive field is nullable on the wire."
- **customer-label-derivation**: a customer's derived `label` MUST be its non-blank `displayName`,
  else its non-blank `email`, else `"—"`, per the source's own doc comment: `displayName || email ||
  "—"`; blank strings (empty, or only whitespace and newlines) count as missing.
- **customer-sublabel-derivation**: a customer's derived `sublabel` MUST be its non-blank `email`,
  else its non-blank `externalId`, else `"—"`, per the source's own doc comment: `email ||
  externalId || "—"`.
- **customer-input-shape**: the customer input MUST be a serializable, comparable value exposing
  non-optional `ecosystemId` and `email` strings, plus four optional string fields — `displayName`,
  `externalId`, `slug`, `avatarUrl` — per the source's own doc comment: "Body for
  `POST /customer/customers` and `PUT /customer/customers/{id}`. Optional fields encode as absent,
  never `null`."
- **customer-input-field-asymmetry**: Unlike `Customer`, whose `email` is
  optional, `CustomerInput.email` MUST be non-optional — every input
  payload declares a concrete email string, never `nil` (see, further
  below, `email-is-trimmed-and-defaults-to-empty-string` and
  `other-four-fields-use-nonBlank`, the two `CustomersTopic` behaviors that
  populate this shape).

### CustomersTopic.swift — navigation, listing, and forms

- **topic-identity**: `CustomersTopic.entry` MUST be the static
  `EcosystemTopicEntry` with `id: "users"`, `label: "Users"`,
  `systemImage: "person.2"`, and `description: "The people who sign in to
  this product."`.
- **topic-single-threaded-state**: the customers topic MUST be a non-subclassable provider of the
  ecosystem topic contract, bound to the UI's serial execution context, and holds a single stored
  data source supplied at construction.
- **email-pattern-and-message-are-shared-constants**:
  `CustomersTopic.emailPattern` MUST be the static string
  `"^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"` and `CustomersTopic.emailMessage` MUST
  be the static string `"Enter a valid email address."`, both consumed by
  `fieldSpec(isRequiredEmail:)`'s `email` field.
- **field-spec-is-shared-and-ordered**:
  `CustomersTopic.fieldSpec(isRequiredEmail:)` MUST return exactly five
  fields in order — `email` (`.text`, label `"Email"`, placeholder
  `"person@example.com"`, `isRequired` set to the parameter,
  `pattern: emailPattern`, `patternMessage: emailMessage`), `displayName`
  (label `"Display name"`, placeholder `"Jane Doe"`), `externalId` (label
  `"External ID"`, placeholder `"auth0|abc123"`), `slug` (label `"Handle"`,
  placeholder `"jane"`), and `avatarUrl` (label `"Avatar URL"`, placeholder
  `"https://…"`) — per the source's own comment, "`isRequiredEmail` is
  always true today; the parameter keeps the create and detail specs
  literally shared."
- **create-spec-uses-first-two-shared-fields**: `createSpec(for:)` MUST
  build its `FormSpec` from `Array(fieldSpec(isRequiredEmail: true)
  .prefix(2))` — the `email` and `displayName` fields only — rather than
  declaring its own field list.
- **detail-spec-uses-all-five-shared-fields**: `detail(for:)` MUST build
  its `FormSpec` from the full, unsliced `fieldSpec(isRequiredEmail: true)`
  — all five fields.
- **child-dispatch-by-rail-path-presence**: `child(for:path:rail:)` MUST
  dispatch on whether `RailPath.id(at: 0, in: path)` is `nil`: when `nil`,
  it returns `.level(listLevel(for:))`; when non-`nil`, it treats that id
  as a customer id and calls `dataSource.get(id:)`.
- **missing-customer-yields-empty-not-error**: When `dataSource.get(id:)`
  throws `HubError.notFound` for the id at path index `0`, `child` MUST
  return `.empty`; any other error thrown by `get(id:)` MUST be re-thrown
  after `HubError.wrap`.
- **users-list-level-shape**: The root level MUST have
  `id: "users-list"`, `title: "Users"`, `emptyMessage: "No users yet."`,
  and one item per customer returned by `list(ecosystemID:)`, each item's
  `id` set to the customer's `id`, `label` set to the customer's `label`,
  `sublabel` set to the customer's `sublabel`, `systemImage: "person"`,
  and `leadsTo: .detail`; it MUST carry a `createAction` titled
  `"New user"` that presents `createSpec(for:)` through
  `FormSheet.present`.
- **list-level-errors-are-wrapped**: When `dataSource.list(ecosystemID:)`
  throws, `listLevel(for:)` MUST catch it and re-throw via
  `HubError.wrap`, so no raw non-`HubError` failure escapes this call.
- **input-builder-is-pure**: the private input-building helper `input(from:ecosystemID:)` MUST be a
  pure function callable from any execution context, because it is invoked from inside a form
  action that runs off the UI context.
- **email-is-trimmed-and-defaults-to-empty-string**: `input(from:ecosystemID:)` MUST set the
  input's `email` to the `"email"` form value trimmed of leading/trailing whitespace and newlines,
  or the empty string `""` when the `"email"` key is absent from the given values — never absent,
  since the input's `email` is non-optional.
- **other-four-fields-use-nonBlank**: `input(from:ecosystemID:)` MUST set `displayName`,
  `externalId`, `slug`, and `avatarUrl` each from the form value only when it is non-blank, so a
  missing key, an empty string, or a whitespace-and-newline-only string all become absent on the
  resulting input — an asymmetry with `email`'s own trim-only handling (see Design Decisions).
- **create-spec-precheck-rejects-case-insensitive-duplicate**: `createSpec(for:)`'s save action MUST
  fetch the ecosystem's current customer list via `list(ecosystemID:)` and throw a validation error
  `A user with email "<email>" already exists.` when an existing customer's `email` matches the
  built input's `email` case-insensitively (treating an absent existing `email` as `""`) — before
  calling `create(_:)`.
- **create-spec-conflict-fallback**: When the precheck passes but
  `dataSource.create(_:)` itself throws `HubError.conflict` (of any
  associated detail), the save action MUST catch it and throw the
  identical `"A user with email \"<email>\" already exists."` validation
  message rather than propagating the raw conflict detail (see **conflict-reason-discarded**
  and Design Decisions).
- **create-spec-other-errors-are-wrapped**: Any error from
  `list(ecosystemID:)` during the precheck, or any error from `create(_:)`
  other than `HubError.conflict`, MUST be re-thrown via `HubError.wrap`.
- **detail-shape-and-seed-values**: `detail(for:)` MUST build an
  `HTDVDetail` (via `FormDetails.form`) with `id: "customer:<customerID>"`,
  `title: "User"`, the five-field `FormSpec` from
  `fieldSpec(isRequiredEmail: true)`, and initial values for all five
  keys, each seeded from the customer's own field or the empty string when
  that field is `nil` (`customer.email ?? ""`, and likewise for the other
  four).
- **detail-save-conflict-fallback**: The detail save action MUST call
  `dataSource.update(id:_:)` directly, with no client-side duplicate
  lookup beforehand, and MUST catch a thrown `HubError.conflict` (of any
  associated detail) and re-throw it as
  `"A user with email \"<email>\" already exists."` — the same message
  `createSpec`'s save produces, but reached only through the server's
  conflict response, never a local list check (see Design Decisions).
- **detail-save-other-errors-are-wrapped**: Any error from
  `update(id:_:)` other than `HubError.conflict` MUST be re-thrown via
  `HubError.wrap`.
- **detail-delete-shape**: `detail(for:)`'s `FormSpec.actions.delete` MUST
  be a `FormDeleteAction` titled `"Delete user"` with
  `confirmationText: "Delete user \"<customer.label>\"? This cannot be
  undone."`, invoking `dataSource.delete(id: customer.id)`.
- **detail-delete-errors-are-wrapped**: When `dataSource.delete(id:)`
  throws, the delete action MUST catch it and re-throw via
  `HubError.wrap`.

