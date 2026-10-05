
Not applicable: no part of this component defines or reads a feature-flag
key; every conditional path (whether an interactive host environment is
present, whether the browser singleton is already set, whether the subject
changed) is derived from the runtime environment or stored session state,
never from a flag this module owns.

