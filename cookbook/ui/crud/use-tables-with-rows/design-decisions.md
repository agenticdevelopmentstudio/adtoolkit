
**Decision**: Each probe is the table's own list request with `limit=1` rather than a separate counting endpoint.
**Rationale**: The source's own doc comment says "has data" is then answered by exactly the authorization and scoping that would serve the rows, "rather than by a second counting path that could disagree with it".
**Approved**: pending

**Decision**: A 403 or 404 puts a table in no set, while any other failure puts it in `unknown` and marks the sweep failed.
**Rationale**: Per the source's doc comment, counting every failure as empty hid tables that hold rows, and when every probe failed the rail said "No data yet." about a scope full of data; a refused or missing list says only that this viewer has nothing to see.
**Approved**: pending

**Decision**: Remembered answers live at module scope with a 60-second freshness window and are revalidated behind a stale answer rather than discarded.
**Rationale**: The source's comment explains that component state died with each remount, so every schema or table click swept dozens of probes again; never asking again kept a table that gained its first row out of the rail until reload, while always asking again swept on every click.
**Approved**: pending

**Decision**: A sweep that fails during revalidation leaves the remembered answer on screen, and no failed sweep is ever stored.
**Rationale**: A failed sweep is partial, so the last good answer is the better guess, and not storing it makes the next mount ask again, which is what the rail's "could not check" state asks of the viewer.
**Approved**: pending

**Decision**: The cache key includes the asking principal, and every answer is dropped when the signed-in principal changes.
**Rationale**: Keys such as a workspace slug or ecosystem id are shared by every member of that workspace, so without the principal the next person to sign in on a machine would be shown the previous one's rail; the subject is used rather than the raw token because a refresh writes a new token for the same user.
**Approved**: pending

