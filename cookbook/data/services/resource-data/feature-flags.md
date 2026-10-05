
Not applicable: no part of this component defines or reads a feature-flag
key. Every conditional path (whether an id is present, whether error
reporting is set, whether a stored view-mode value is valid) is derived
from a caller argument or stored state, never from a flag this module owns.

