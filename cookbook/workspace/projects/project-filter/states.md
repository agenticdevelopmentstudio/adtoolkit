
Not applicable — this is a substring-matching operation pair, not a
visual component. It has no runtime state machine of its own; it is
called anew on every keystroke by its callers' own filter steps, which
hold the query text and the resulting row list, not this component.

