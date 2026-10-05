
This is a presentational detail-panel section that renders a subject's admin
notes and its history, stacked in a single container. It is
parameter-driven: the caller fetches the data and passes it in — the
component itself never fetches anything. Notes and history are independent:
each has its own optional loading flag, so a slow history fetch never
withholds already-loaded notes, and vice versa.

### Types

- **Admin note** fields: `id`, `content`, `author`, `addedDate`,
  `modifiedDate`, `subjectTable`, `subjectId`. The component reads only
  `id`, `content`, `author`, and `modifiedDate`; `addedDate`,
  `subjectTable`, and `subjectId` are part of the data shape but are not
  rendered here.
- **History entry** fields: `id`, `actor`, `action`, `timestamp`. The
  component reads all four fields.
- Date formatting: `modifiedDate` and `timestamp` arrive as plain
  `YYYY-MM-DD` strings, already formatted before this component ever sees
  them. The component MUST NOT parse, reformat, or re-localize either
  field; it renders whatever string arrives on the corresponding
  parameter.

