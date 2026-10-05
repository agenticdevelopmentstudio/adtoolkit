
Not applicable: none of the six utilities constructs a user-facing string.
The secret store's and the logger factory contract's only string output is
diagnostic log text (see Logging below), never text displayed to a user;
semantic-version parsing and text folding operate on caller-supplied data,
not on any string this recipe itself presents to a user.

