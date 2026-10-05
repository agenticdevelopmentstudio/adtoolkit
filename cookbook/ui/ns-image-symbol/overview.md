
The symbol image is a lookup that turns a system symbol name into an image
and never answers "nothing". A system symbol lookup fails for a misspelled
name or for a symbol the running operating system version does not ship, and
a caller that force-unwraps that failure crashes whatever view happened to
build the control. This component answers a blank template image of symbol
size instead, so the control still lays out and still carries its
accessibility description.

