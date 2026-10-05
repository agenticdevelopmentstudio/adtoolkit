
Not applicable: no file in this module calls `console.log`,
`console.warn`, `console.error`, or any platform logging API. Every
failure this module detects is either remapped and rethrown
(`games-create-conflict-mapping`, `jsonb-write-refuses-unparseable-text`)
or propagated unchanged; logging that failure is the caller's
responsibility.

