
`docsApi.createCategory` surfaces a hardcoded English error string on a
name conflict — `A category named "<name>" already exists somewhere
else.` (`create-category-conflict-message`) — with no lookup table or
locale parameter anywhere in `docs.ts` or the `markdownApi.createCategory`
call it forwards to. This is the only user-facing string this component
introduces; every other error this component's operations can produce is
whatever `authedJson`/`authedRequest` throws, defined outside this file.

