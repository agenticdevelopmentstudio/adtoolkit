
Not applicable: this logic authors no user-facing string of its own — the source contains no thrown
error with an English message anywhere in this recipe (unlike some sibling clients' own validation
errors). Every error message a caller can observe from this module originates in the backend's response
body and is extracted by the shared authenticated request client, not authored here.

