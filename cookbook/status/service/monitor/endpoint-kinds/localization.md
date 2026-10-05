
Not applicable: this module renders no text to any user and calls no logging function of its own; its six literal strings (`http`, `frontend`, `admin`, `health`, `custom`, `dns`) are compared programmatically inside the membership check and looked up in the non-deploy kind set, never displayed. The same literal words are shown, unlocalized, in the separate frontend copy's editor dropdown, but that is a different module, outside this recipe's given source.

