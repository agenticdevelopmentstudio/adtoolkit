
The engine has no localized strings. Its only human-readable text is hardcoded English, carried in a `failed` event's message: the engine's internal error descriptions "push made no progress", "pull made no progress" and "manifest unstable", the literal "repeated resync_required from server; backing off", and a description of any other error. A host that shows these to users must map them itself.

