
None of the given sources externalize strings into a localization resource
system; the following are hardcoded, English-only strings that are facts
about the current implementation, not gaps:

- The fixed token placeholder (`'YOUR_TOKEN'`) is embedded verbatim, in
  English, in every generated command-line/scripting snippet.
- The slug index's collision message (`endpoint slug collision on
  "${slug}"...`) is a hardcoded English developer-facing error string.
- The CRUD resource state's reliance on an inherited hardcoded English error
  message for an unexpected `204` response (see Platform Notes) is inherited,
  not produced, by this recipe's own logic.

