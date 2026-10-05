
Not applicable — no file in either implementation defines or reads a
feature-flag key. Every conditional path (manageability, notFound-as-empty,
slug drift healing, workspace vs. caller scoping) is derived from a model
field, a thrown error's shape, or a caller-supplied option, never from a
flag this component owns.

