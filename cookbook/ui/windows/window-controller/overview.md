
Two small generic types, defined together, give call sites typed access to a
window's content instead of the untyped content controller that the
single-instance window base's content accessor returns.

The window controller is an open subclass of the single-instance window base
(see `adtoolkit://cookbook/ui/windows/single-window-controller`, which
this recipe depends on and does not restate) that adds exactly one member: a
computed typed accessor that downcasts the base's content to a
caller-supplied content-controller type. It overrides nothing else and
declares no initializer of its own, so every other behavior — lazy window
construction, frame/visibility persistence, HUD chrome, front-ordering under
quiet presentation, the singleton protocol extension — is exactly what the
base class specifies.

The content wrapper is a separate, unrelated-by-inheritance content
controller that wraps a single strongly-typed view as a content controller's
content, for call sites that need a content controller (e.g. to hand to the
window controller's content accessor) but only have a view. It stores the
view at construction and overrides the view-loading step to install it
directly, bypassing nib/resource loading entirely.

