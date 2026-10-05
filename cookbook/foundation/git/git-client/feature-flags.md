
Not applicable: no part of this component defines or reads a feature-flag
key. Submodule handling is caller-configured state, not a flag, and every
conditional path (the executable check, the submodule setting, an exit
status) is derived from configuration or from git's own output, never from
a flag this component owns.

