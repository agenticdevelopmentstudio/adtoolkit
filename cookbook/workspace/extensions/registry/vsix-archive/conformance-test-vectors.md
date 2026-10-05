
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| vsix-archive-001 | sha256-hex-format | Compute the digest of the bytes `"the archive"` | Returns lowercase hex equal to the SHA-256 digest of the same bytes |
| vsix-archive-002 | digest-comparison-normalized, digest-match-result | Verify with the expected digest supplied as the correct digest, uppercased and padded with leading/trailing whitespace and a trailing newline | Returns digest-status "matched," with the digest value equal to the expected digest |
| vsix-archive-003 | digest-mismatch | Verify with an expected digest of 64 repeated `"a"` characters | Fails with a digest-mismatch error carrying the expected value and the actual computed digest |
| vsix-archive-004 | digest-not-published-result, signature-neither-published | Verify with no expected digest, no signature, and no public key | Returns digest-status "not published," signature-status "not published," and the digest value equal to the computed digest |
| vsix-archive-005 | signature-verified-with-real-key | Verify with the correct digest, a signature archive, and a public key, where the signature is a real Ed25519 signature over the archive bytes | Returns signature-status "registry attested" |
| vsix-archive-006 | signature-invalid | Verify substituted bytes with a digest, signature, and key that sign a different byte string than the substituted bytes | Fails with a signature-invalid error |
| vsix-archive-007 | signature-invalid | Verify with a signature archive whose `.signature.sig` bytes were corrupted after signing | Fails with a signature-invalid error |
| vsix-archive-008 | signature-half-pair-refused | Verify with no expected digest, a signature archive, and no public key | Fails with a signature-incomplete error naming `"publicKey"` |
| vsix-archive-009 | signature-half-pair-refused | Verify with no expected digest, no signature, and a public key | Fails with a signature-incomplete error naming `"signature"` |
| vsix-archive-010 | public-key-parsing | Verify with a public key whose PEM body is not valid base64 | Fails with a public-key-unreadable error |
| vsix-archive-011 | public-key-parsing | Verify with a public key whose PEM body decodes to 64 bytes, not the required 44 | Fails with a public-key-unreadable error |
| vsix-archive-012 | signature-archive-extraction | Verify with a signature archive containing only an unrelated `readme.txt`, no `.signature.sig` | Fails with a signature-archive-unreadable error |
| vsix-archive-013 | digest-checked-before-signature | Verify with a wrong expected digest, alongside a signature and key that would otherwise verify | Fails with a digest-mismatch error, not a signature error |
| vsix-archive-014 | expand-uses-ditto, expand-success-preserves-destination | Expand an archive built from a staging directory holding `extension/package.json` | The payload directory's `package.json` exists after the call |
| vsix-archive-015 | expand-destination-must-not-exist | Expand to a destination that already exists as a directory | Fails with a destination-exists error naming the destination |
| vsix-archive-016 | expand-nonzero-status-cleanup, expand-cleanup-is-best-effort | Expand a file that is not a valid archive | Fails, and the destination does not exist afterward |
| vsix-archive-017 | expand-byte-ceiling-watchdog, expand-abort-cleanup | Expand, with a byte ceiling of 1,048,576 and a check interval of 0.005 seconds, an archive that expands to 64 MB | Fails with an expansion-too-large error naming 1,048,576; the destination does not exist afterward |
| vsix-archive-018 | expand-byte-ceiling-watchdog | Same archive shape, byte ceiling 67,108,864, check interval 0.005 seconds | Completes without failing; the payload directory's `package.json` exists |
| vsix-archive-019 | byte-ceiling-exceeds-artifact-cap | Compare the expansion byte ceiling and the registry client's maximum download size | The expansion byte ceiling is greater |
| vsix-archive-020 | expand-path-traversal-containment | Expand an archive with entries `extension/package.json` and a relatively-named `../escaped.txt` | `escaped.txt` does not exist one level above the destination; it exists inside the destination |
| vsix-archive-021 | expand-path-traversal-containment | Expand an archive with an entry named by an absolute path inside the test's own scratch directory | The absolute target does not exist; the same path, re-rooted under the destination, does exist |
| vsix-archive-022 | expand-symlink-escape-failure, expand-nonzero-status-cleanup | Expand an archive containing a symlink entry pointing outside the destination followed by an entry written through it | Fails with an expansion-failed error carrying a non-zero status and a non-empty message; the file is not planted outside, and the destination does not exist |
| vsix-archive-023 | expand-timeout-cleanup | Expand with a timeout of 0.001 seconds | Fails with an expansion-timed-out error naming 0.001 seconds; the destination does not exist afterward |
| vsix-archive-024 | expand-default-parameters | Compare the default expansion timeout to the published default | Equals 120 |
| vsix-archive-025 | expand-uses-ditto, expand-success-preserves-destination | Expand a hand-built archive containing only `extension/package.json` with content `{"name": "widget"}` | The expanded `package.json` at the payload directory reads back exactly `{"name": "widget"}` |

