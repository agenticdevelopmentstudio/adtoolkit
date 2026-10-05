
- The add control carries accessibility identifier `file-browser.add-directory`
  and the remove control carries `file-browser.remove-directory`.
- Both footer controls set a tooltip (static for add, dynamic for remove —
  see Behavioral Requirements); neither sets an explicit accessibility label
  or title, and both are built with an icon image explicitly given no
  accessibility description.
- Neither footer control has an explicit accessibility label or title: both
  have no title text, an icon image with no accessibility description, and
  no accessibility label/title set anywhere — only the accessibility
  identifier is set (see above). A screen reader therefore has no
  developer-supplied name to announce for either control, only whatever
  generic fallback the platform's default control accessibility provides.
- Not applicable: the hosted tree's own accessibility (row roles, disclosure
  state announcements, selection announcements) belongs to the hosted file
  tree, a separate component with its own recipe; this recipe covers only
  what this component itself renders and wires (the footer and the
  container).
- Not applicable: minimum tap target. This is a pointer-driven desktop
  control, not a touch surface, so the template's 44×44pt touch-target
  guidance does not apply; the footer controls are given no explicit
  width/height — their size comes from the platform's intrinsic sizing for
  an accessory-style control with an icon.

