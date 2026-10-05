
Vectors 001–015 come from the module's own test suite. Vectors 016–018 follow from the code and from WHATWG URL parsing.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| peer-url-001 | normalize-trim, normalize-strip-trailing-slashes | The normalize operation on `"  https://b.example.com/// "` | `"https://b.example.com"` |
| peer-url-002 | normalize-canonical-form, normalize-idempotent | The normalize operation on `"https://b.example.com"` | `"https://b.example.com"` |
| peer-url-003 | normalize-keep-path | The normalize operation on `"https://b.example.com/status/"` | `"https://b.example.com/status"` |
| peer-url-004 | normalize-lowercase | The normalize operation on `"HTTPS://B.Example.COM"` | `"https://b.example.com"` |
| peer-url-005 | normalize-default-port | The normalize operation on `"https://b.example.com:443"` | `"https://b.example.com"` |
| peer-url-006 | normalize-default-port | The normalize operation on `"http://b.example.com:80"` | `"http://b.example.com"` |
| peer-url-007 | normalize-drop-query-fragment | The normalize operation on `"https://b.example.com/?x=1#frag"` | `"https://b.example.com"` |
| peer-url-008 | normalize-keep-port | The normalize operation on `"http://localhost:3000/"` | `"http://localhost:3000"` |
| peer-url-009 | normalize-total | The normalize operation on `"  b.example.com/ "` | `"b.example.com"`, no exception |
| peer-url-010 | valid-http-https | The validity-check operation on `"https://b.example.com"` | `true` |
| peer-url-011 | valid-http-https | The validity-check operation on `"http://localhost:3000"` | `true` |
| peer-url-012 | valid-trim, valid-no-normalize-required | The validity-check operation on `"  https://b.example.com/ "` | `true` |
| peer-url-013 | valid-unparseable | The validity-check operation on `"b.example.com"`, on `"/relative"`, on `""` | `false` each, no exception |
| peer-url-014 | valid-other-scheme | The validity-check operation on `"ftp://b.example.com"` | `false` |
| peer-url-015 | valid-other-scheme | The validity-check operation on `"javascript:alert(1)"`, on `"file:///etc/passwd"` | `false` each |
| peer-url-016 | normalize-drop-userinfo | The normalize operation on `"https://user:pw@b.example.com/"` | `"https://b.example.com"` |
| peer-url-017 | normalize-total | The normalize operation on `""` | `""` |
| peer-url-018 | normalize-total | The normalize operation on `"B.Example.COM/"` (unparseable) | `"B.Example.COM"`, case unchanged |

