
A use facet is one of ten fixed values (`coding`, `conversation`,
`problemSolving`, `research`, `writing`, `vision`, `agents`, `translation`,
`speech`, `economy`) naming "what a model is good for" — the axis a
gateway's hard capabilities (tools/reasoning/vision) and a raw description
sentence do not answer on their own. It is a **logic** component with no
visual surface of its own: a pure keyword-matching heuristic that derives
facets from text and capabilities, a convenience wrapper that reads a
resolved model's description, `goodFor` and an optional extra blurb, and an
any-of set filter that "Good for" filter controls use to hide or show
models. Facets are derived on demand rather than stored, because the
evidence text a model carries arrives from three different places at three
different times (the shared model catalog, a provider template's curated
model details, and a local server's live-fetched blurb).

