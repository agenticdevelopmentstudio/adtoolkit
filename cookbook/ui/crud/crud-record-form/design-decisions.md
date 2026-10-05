
**Decision**: Fields are generated from `CrudTableMeta`, not hand-authored.
**Rationale**: one form serves every generic-CRUD table; new tables need no new
form code.
**Approved**: pending

**Decision**: `serverManaged` columns are skipped; `createOnly` columns are
disabled + stripped on edit.
**Rationale**: the form only ever offers what the backend will actually accept,
so a save can't silently no-op.
**Approved**: pending

**Decision**: Untouched optional fields are omitted on create rather than sent
as empty.
**Rationale**: the backend OpenAPI spec (surfaced via `gen_table_metadata.py`)
carries no column defaults, so sending `''`/`false` would override a DB
default; omission lets the backend default win.
**Approved**: pending

**Decision**: (React/Web) Validation throws field-named errors surfaced
inline via `useAction`.
**Rationale**: the message names the offending column and the draft is
retained, so the fix is obvious and non-destructive.
**Approved**: pending

**Decision**: (React/Web) Object/array/unknown columns use a JSON textarea and
round-trip via `JSON.parse`/`stringify`.
**Rationale**: jsonb columns must survive edit without a plain-text path
corrupting an object to "[object Object]".
**Approved**: pending

**Decision**: The draft is a flat text/boolean buffer coerced only at submit.
**Rationale**: controls stay simple (all text/checkbox), and type coercion +
validation live in one place (`buildPayload`).
**Approved**: pending

**Decision**: Create vs. edit mode is inferred from whether `initial` is
supplied (`mode = initial ? 'edit' : 'create'`), with no separate mode prop.
**Rationale**: a single source of truth for mode rules out a caller passing a
row and a conflicting mode flag out of sync with each other.
**Approved**: pending

