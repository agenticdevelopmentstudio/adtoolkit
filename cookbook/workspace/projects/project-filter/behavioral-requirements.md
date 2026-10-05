
- **empty-query-yields-no-ranges**: Finding ranges MUST return no ranges
  immediately when the query is empty, without inspecting the text.
- **literal-substring-matching**: Finding ranges MUST treat the query as a
  literal substring, not a regular expression — it MUST search with a
  case-insensitive-only literal comparison, never a pattern/regex search,
  so a query containing regex metacharacters (e.g. `"."`, `"*"`, `"["`)
  MUST match only that literal character sequence.
- **case-insensitive-matching**: Finding ranges MUST locate occurrences of
  the query in the text using case-insensitive comparison, so a query and
  text differing only in letter case MUST still match.
- **utf16-range-coordinates**: Each returned range MUST express its
  position and length in UTF-16 code units of the text, not in
  character-cluster offsets — this is deliberate: UTF-16 code-unit offsets
  are the coordinate system many platforms' highlighted-text
  representations (attributed strings) index by, and a character-cluster
  offset would have to be converted at every call site to be of any use
  here.
- **all-occurrences-returned-left-to-right**: Finding ranges MUST return
  every occurrence of the query found by scanning the text left to right,
  in the order encountered, and MUST NOT stop after the first occurrence.
- **non-overlapping-scan-advance**: After finding a match, the scan MUST
  resume at the match's position plus its length (or plus one position for
  a zero-length match) before searching for the next occurrence, so an
  occurrence that would overlap the just-found match (e.g. a second
  `"aa"` starting inside a first `"aa"` match within `"aaa"`) MUST NOT be
  reported as a separate range.
- **empty-text-yields-no-ranges**: Finding ranges MUST return no ranges
  when the text is empty, for any non-empty query, because the scan has
  nothing to scan.
- **ranges-loop-terminates**: Because the scan position strictly increases
  by at least one UTF-16 unit every iteration and is bounded by the text's
  length, finding ranges MUST return after at most as many iterations as
  the text is long, for any text/query pair — it MUST NOT loop
  indefinitely.
- **empty-query-matches-every-repo**: Checking a match MUST return true
  for any repository record when the query is empty, without inspecting
  the record's name or path.
- **matches-by-name-or-path-only**: For a non-empty query, checking a
  match MUST return true if and only if the query is found somewhere in
  the record's name or somewhere in its path; matching against the
  record's remote URL, identifier, first-seen time, last-seen time, or
  last-opened time MUST NOT affect the result, since checking a match
  reads only the record's name and path.
- **matches-short-circuits-on-name**: Checking a match MUST check the
  record's name before its path, and MUST NOT check the path at all when
  the name check already found a match.
- **single-source-for-filter-and-highlight**: A caller deciding which rows
  to keep (via checking a match) and a caller deciding which characters to
  highlight in a kept row (via finding ranges) MUST derive both decisions
  from this component's own scan logic; no caller MUST implement a
  separate substring search of its own, so the set of matched characters a
  row displays MUST always be consistent with the reason that row was
  kept.
- **stateless-and-pure**: This component MUST hold no internal state of
  its own, and both finding ranges and checking a match MUST be pure
  functions of their arguments — calling either operation repeatedly with
  the same arguments, from any thread, MUST return an equal result every
  time.

