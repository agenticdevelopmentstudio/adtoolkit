
This logic is the single source of truth for how the application
identifies a deploy project. It provides two pure functions:

- the key function builds the identity key `platform|projectName` from
  the raw (un-canonicalized) platform string and the project name.
- the de-duplication function collapses a list of deploy-project entries that
  share a `(platform, projectName)` pair down to the first-seen entry.

The reasoning behind it: the auto-configure review view builds its ignore
collection from these keys and the auto-configure provider tests entries against
the same collection, so both must produce byte-identical keys ("a separator/field
drift would otherwise silently make every ignore a no-op"). De-duplication
exists because Railway enumerates one deploy-project entry per environment
(production/staging/testing), while the "Set Platform Project" picker and the
project-level ignore review treat a project as a single unit.

Callers: the auto-configure provider (builds the ignore list and the review
project list), the auto-configure review view (ignore checkbox state), the
platform projects view (bulk ignore request), and the project browser view
(project picker list).

