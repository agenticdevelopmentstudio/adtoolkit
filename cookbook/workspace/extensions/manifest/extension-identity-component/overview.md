
This component defines a single safety check that decides whether a string
an extension manifest claims as its identity (a publisher, name, or version
field) may be spliced as a single path or URL component. Two collaborators —
one that installs an extension bundle and one that reaches a registry's
detail endpoint — call this check before joining an identifier and version
into an install directory name, and before joining a namespace, name, and
version onto a registry detail URL — one check shared by both splice sites.

