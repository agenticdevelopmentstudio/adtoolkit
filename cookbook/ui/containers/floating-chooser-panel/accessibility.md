
- Role/traits: Not applicable at this layer — the controller sets no
  accessibility role, trait, or identifier of its own; the standard panel
  role applies, and interactive elements (list rows, search fields,
  buttons) belong to whichever content component an extending component
  hosts, each with its own recipe.
- Keyboard/focus: The panel MUST become the key window before the
  initial-focus hook is called (showing the panel makes the window key and
  brings it to the front, then calls the initial-focus hook), so an
  extending component's initial-focus hook can always assume the window is
  already key. No explicit focus-restoration code exists in this file
  beyond closing the panel itself; losing key status when the panel closes
  is standard platform behavior.
- Label requirements: Not applicable — no accessibility label or identifier
  is assigned to the window or the container view in this file.
- Announce state changes: Not applicable — the panel has no loading or
  disabled state to announce.
- Minimum tap target: Not applicable — this controller renders no
  interactive control of its own; the window's standard title-bar buttons
  are explicitly hidden, and the hosted content's controls are covered by
  that content component's own recipe.

