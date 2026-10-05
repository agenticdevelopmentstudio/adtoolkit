
- **inherits-single-window-controller-lifecycle**: The window controller
  MUST inherit all window build, frame-persistence, visibility-persistence,
  and HUD behavior unchanged from the single-instance window base (see
  `adtoolkit://cookbook/ui/windows/single-window-controller`), since it
  overrides no member of the base.
- **exposes-typed-view-controller-accessor**: The window controller MUST
  expose a computed typed accessor equal to the base's content, downcast to
  the caller-supplied content-controller type.
- **returns-nil-for-non-matching-content-view-controller**: The typed
  accessor MUST evaluate to absent whenever the base's content is absent or
  is not an instance of the caller-supplied content-controller type.
- **declares-no-additional-initializer**: The window controller MUST declare
  no initializer of its own, so construction and archive-based-construction
  behavior remain exactly the base class's.
- **exposes-typed-content-view-property**: The content wrapper MUST expose a
  content-view property, of the caller-supplied view type, set once, at
  construction.
- **initializes-view-controller-with-supplied-content-view**: Constructing
  the content wrapper with a supplied view MUST assign the given view to the
  content-view property and complete the base content-controller
  construction with no resource/nib reference.
- **provides-parameterless-convenience-initializer**: The content wrapper
  MUST expose a parameterless convenience construction path that constructs
  a default instance of the caller-supplied view type and forwards it to the
  view-supplying construction path.
- **fails-at-runtime-on-archive-initialization**: Archive-based construction
  of the content wrapper MUST trap with a fatal error at runtime, so
  decoding-based initialization is unsupported.
- **installs-content-view-directly-in-load-view**: The view-loading step
  MUST be overridden to install the content-view property as the
  controller's view directly, with no nib/resource loading or additional
  view hierarchy construction.

