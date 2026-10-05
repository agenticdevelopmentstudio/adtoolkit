
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| setup-stamp-001 | missing-needs-setup | Check a stamp URL that does not exist. | Setup is needed (test: testMissingStampNeedsSetup). |
| setup-stamp-002 | record-writes-version, equal-version-no-setup | Record `1.2.3`, then check with bundle version `1.2.3`. | Setup is not needed (test: testRecordedSameVersionDoesNotNeedSetup). |
| setup-stamp-003 | any-difference-needs-setup | Record `1.2.3`, then check with `1.2.4` and with `1.2.2`. | Setup is needed in both directions (test: testDifferentVersionNeedsSetupInEitherDirection). |
| setup-stamp-004 | whitespace-ignored | Write `1.2.3\n` to the stamp, then check `1.2.3`. | Setup is not needed (test: testWhitespaceInStampIsIgnored). |
| setup-stamp-005 | default-location | Ask for the default URL with directory name `MyApp`. | The path ends with `Library/Application Support/MyApp/last-setup-version` (test: testDefaultURLShape). |
| setup-stamp-006 | record-writes-version | Record a version to a URL whose parent directory does not exist. | The directory is created and the file written. |

