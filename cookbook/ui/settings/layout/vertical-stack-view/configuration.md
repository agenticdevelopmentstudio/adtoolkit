
Not applicable: the component exposes no caller-configurable options
through its own constructor or setters. Its only public constructor takes
no parameters; the frame-accepting constructor accepts but discards its
argument (see Design Decisions), and a deserializing/decoding-based
construction path fails unconditionally. Orientation and spacing are
fixed at construction and are not exposed as settable properties on the
component itself. The public internal-stack-view property (see
**exposes-stack-view-as-public-property**) does let a caller reconfigure
the internal stack view directly after construction (see Design
Decisions) — but this is a consequence of that property's visibility, not
a formal configuration option this component defines.

