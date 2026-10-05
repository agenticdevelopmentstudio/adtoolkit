
| String Key | Default (en) | Context |
|-----------|---------------|---------|
| — | An organization with that slug already exists. | Thrown by the create operation when the backend reports a slug conflict |
| — | That organization slug is already taken. | Thrown by the rename operation when the backend reports a slug conflict |
| — | That organization's handle has been taken, so it can't be restored. | Thrown by the restore operation when the backend reports a 409 |

There is no localization mechanism in this domain (no catalog, no key, no lookup call) — the three
strings above are fixed English literals, stated as fact per the non-UI component guidance rather
than as a hidden gap (see Compliance). Every other error message a caller can observe originates
in the backend's response body and is extracted by the shared authenticated request client, not
authored here.

