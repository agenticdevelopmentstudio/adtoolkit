
Not applicable: the source declares no feature-flag or configuration-flag
lookup — every call to `search`, `detail`, `data`, or `text` runs the same
fixed logic unconditionally on every invocation (traced to the absence of
any flag check anywhere in the source).

