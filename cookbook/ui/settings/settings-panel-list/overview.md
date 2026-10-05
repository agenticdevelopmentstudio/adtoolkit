
The Panel List is the sidebar of a settings split view: a domain-agnostic,
sectioned list component specialized for settings panels. Its ancestor
topic list component is a domain-agnostic sectioned list that knows nothing
about settings; this component maps an ordered array of panels onto that
ancestor's row model and translates the ancestor's generic row-selection
callback back into the specific panel the reader picked.

Beyond what its ancestor already renders and themes, this component owns
three concerns: (1) turning each panel's descriptor into a row, (2)
narrowing the visible rows by a live search query, delegated to a settings
search index, and (3) keeping a row's identity — the panel's index in the
full, unfiltered array — stable across filtering, so a caller (the settings
split view) can select, query the visibility of, and arrow-key through
panels by index no matter what the search field currently hides.

