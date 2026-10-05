
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| webview-host-document-001 | bootstrap-injection-point, head-tag-closing-detection | `wrapping: "<html><head><title>x</title></head><body>hi</body></html>", initialState: absent` | Bootstrap script text appears strictly between `<head>` and `</head>` |
| webview-host-document-002 | bootstrap-injection-point | `wrapping: "<html><head><script>acquireVsCodeApi()</script></head><body></body></html>", initialState: absent` | The bootstrap's occurrence of the message channel name precedes the extension's own `acquireVsCodeApi()` text |
| webview-host-document-003 | bootstrap-prepend-fallback | `wrapping: "<p>hi</p>", initialState: absent` | Bootstrap precedes `<p>hi</p>` in the returned document |
| webview-host-document-004 | bootstrap-prepend-fallback | `wrapping: "<html><body>hi</body></html>", initialState: absent` | Bootstrap precedes the given markup in the returned document |
| webview-host-document-005 | bootstrap-prepend-fallback | `wrapping: "", initialState: absent` | Returned document contains the bootstrap's message channel name occurrence; nothing else is present to compare against |
| webview-host-document-006 | head-tag-match-case-insensitive, head-tag-closing-detection | `wrapping: "<HTML><HEAD></HEAD><BODY>hi</BODY></HTML>", initialState: absent` | Bootstrap injected strictly between `<HEAD>` and `</HEAD>` |
| webview-host-document-007 | extension-markup-passthrough | `wrapping: "<html><head></head><body><p>café &amp; crème</p><img src=\"a#b.png\"></body></html>", initialState: absent` | Returned document contains the given `<body>...</body>` substring unchanged |
| webview-host-document-008 | initial-state-undefined-vs-value | `wrapping: "<html><head></head><body></body></html>", initialState: "{\"scrollTop\":42}"` | Returned document contains `42` |
| webview-host-document-009 | script-close-tag-neutralized | `initialState: "{\"note\":\"</script><script>alert(1)</script>\"}"` | Returned document does not contain `<script>alert(1)` literally and does not contain the raw payload unescaped |
| webview-host-document-010 | html-comment-open-neutralized | `initialState` note field containing each of `<!--`, `-->`, `<!--<script>`, `</SCRIPT >` in turn | Returned document does not contain that raw payload unescaped, for every one of the four inputs |
| webview-host-document-011 | initial-state-undefined-vs-value | `wrapping: "<html><head></head><body></body></html>", initialState: absent` | Returned document contains the bare token `undefined` |
| webview-host-document-012 | message-handler-name-constant | Reading the message channel name constant | Equals `"agenticWebview"`; first character is a letter; every character is a letter or digit |
| webview-host-document-013 | message-kind-closed-set | Every message kind value, checked against a rendered bootstrap | Every kind's wire value appears in the rendered document |
| webview-host-document-014 | quoted-attribute-ambiguity-bailout | `wrapping: "<p>x</p><head data-x=\">oops\">content</head>"` (a quoted attribute containing `>`) | The head-location search finds no match; the bootstrap is prepended before `<p>x</p>` rather than inserted mid-attribute |
| webview-host-document-015 | head-vs-header-disambiguation | `wrapping: "<header>nav</header><head></head>"` | The bootstrap is inserted inside the real `<head></head>`, not before `<header>` |
| webview-host-document-016 | acquire-once-guard | The literal text of the rendered bootstrap script | Contains the exact substring `already been acquired` guarded by an `if (acquired)` check |

