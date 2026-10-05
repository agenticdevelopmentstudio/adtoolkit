
- The title property is an overridable plain-text property, not a bound,
  localization-aware text value. The base class supplies only the
  empty-string default; whichever plain text a subclass returns from its
  override is assigned directly to the window's title and is therefore
  unlocalized unless the subclass itself localizes it. This is the
  subclass's responsibility, not this class's — the base class introduces no
  localizable or unlocalized string literal of its own.

