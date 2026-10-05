
- **returns-system-symbol-when-available**: When the system provides a
  symbol with the given name, the lookup MUST return that system image with
  the given accessibility description applied.
- **never-returns-nothing**: The lookup MUST always return an image; it MUST
  NOT fail, trap or return an absent value for any name, including an empty
  or misspelled one.
- **blank-fallback-is-symbol-sized**: When the system provides no symbol with
  the given name, the returned image MUST be a blank image of 16 by 16 points.
- **blank-fallback-is-template**: When the system provides no symbol with the
  given name, the returned image MUST be marked as a template image so the
  control that shows it tints it like a real symbol.
- **blank-fallback-keeps-description**: When the system provides no symbol
  with the given name, the returned image MUST carry the accessibility
  description that was passed in, so assistive technology still names the
  control.
- **description-is-optional**: The accessibility description MAY be absent;
  an absent description MUST be carried through unchanged on both the system
  image and the fallback image.
- **no-diagnostic-on-fallback**: The lookup MUST NOT log, throw or otherwise
  signal that a fallback was used; a missing symbol is visible only as a
  blank image.

