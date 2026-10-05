
Not applicable: the component renders no markup of its own — it delegates
its entire visual output to one composed command-palette instance. Corner
radius, padding, font, background, foreground, border, shadow, and
min/max size are all owned by that composed interaction (and the modal
dialog it renders into), not by this component.

