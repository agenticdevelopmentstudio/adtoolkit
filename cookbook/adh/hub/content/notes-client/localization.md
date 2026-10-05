
`notesApi.createCategory` surfaces `markdownApi.createCategory`'s hardcoded English error string on a name conflict — `A category named "<name>" already exists somewhere else.` (`create-category-conflict-message`) — with no lookup table or locale parameter anywhere in `notes.ts`. This is the only user-facing string this component's own call graph can produce beyond a raw thrown error; every other error `notesApi`'s operations can produce is whatever `authedJson`/`authedRequest` throws, defined outside this file.

