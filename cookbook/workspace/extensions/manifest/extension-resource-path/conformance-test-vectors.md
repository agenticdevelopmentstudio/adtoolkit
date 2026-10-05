
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| erp-001 | single-base-resolve, candidate-construction | Resolving `"./themes/dark.json"` inside a directory | resolves to the canonical `directory/themes/dark.json` location |
| erp-002 | candidate-construction | Resolving `"snippets/x.code-snippets"` inside a directory (no leading `./`) | resolves to `directory/snippets/x.code-snippets`; a leading `./` is not required |
| erp-003 | directory-flag-forcing | Resolving `"./themes/dark.json"` inside a directory location carrying no directory marking | resolves inside the directory, not beside it |
| erp-004 | escape-refusal, error-payload-fidelity | Resolving `"../outside/secret.json"` inside an extension directory that is a child of a parent directory | fails with the escape error, declared `"../outside/secret.json"`, resolved to the parent directory's `outside/secret.json` canonical path |
| erp-005 | error-message | The description of an escape error with declared `"../x.json"`, resolved `"/tmp/x.json"` | the description contains both `"../x.json"` and `"/tmp/x.json"` |
| erp-006 | single-base-resolve, escape-refusal | Resolving `"../base.json"` relative to a themes directory, contained in a root directory, then resolving `"../../base.json"` the same way | the first resolves to `root/base.json`; the second fails with the escape error |
| erp-007 | component-wise-comparison, containment-inputs-uncanonicalized | The containment check on a candidate whose directory name is the base's name with `-evil` appended | returns false even though the candidate's path string has the base's path as a literal string prefix |
| erp-008 | containment-strictness, containment-inputs-uncanonicalized | The containment check on a base directory checked against itself | returns false |
| erp-009 | containment-strictness, containment-inputs-uncanonicalized | The containment check on a descendant three levels below the base | returns true |
| erp-010 | symmetric-canonicalization | Resolving `"./themes/dark.json"` relative to a symlink pointing at a real directory, contained in that real directory | resolves to `realDirectory/themes/dark.json`, treating the symlinked and real directories as equal |
| erp-011 | escape-refusal, symmetric-canonicalization | Resolving `"./escape/secret.json"` inside a directory whose `escape` entry is a symlink pointing to a sibling directory outside it | fails with the escape error, even though the declared string itself contains no `..` |
| erp-012 | application-support-composition | Composing the application-support location for app name `"Coffee Grinder"`, subdirectory `"Extensions"` | the result's last three path components, in order, are `"Application Support"`, `"Coffee Grinder"`, `"Extensions"` |
| erp-013 | application-support-composition | Composing the application-support location for the same app with subdirectory `"Plugins"` versus `"Extensions"` | both results share the same parent directory |
| erp-014 | home-dot-directory-composition | Composing the home dotfolder location for `"agenticextensions"` and `"agenticplugins"`, given the same fixture home directory | results equal the fixture home directory appended with `.agenticextensions` and `.agenticplugins` respectively |
| erp-015 | home-directory-default | Composing the home dotfolder location for `"agenticextensions"` with an explicit fixture home directory, compared with the same call using the default home directory | the two results differ, and the default result's parent path equals the process's real home directory |
| erp-016 | filesystem-side-effects | Resolving a path inside a scratch directory, enumerating the directory's contents before and after the call | the directory's entries are unchanged; no file or folder is created, deleted, or modified by the call |
| erp-017 | safe-across-any-concurrency-domain, stateless-synchronous-operation | Resolving a path against a single directory, invoked concurrently from many independent callers against the same directory with different declared strings | every call completes with the result its own input implies, with no crash and no shared-state corruption |
| erp-018 | application-support-composition | Composing the application-support location on a host where the user domain reports no Application Support directory | returns absent |

