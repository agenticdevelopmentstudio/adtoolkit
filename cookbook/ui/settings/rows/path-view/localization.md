
The path and caption are entirely caller-supplied at the call site, not
literals owned by this component. But the code that builds the caption
prefix hardcodes the `": "` separator as a literal, user-visible glue
string, not routed through a localization API. Its punctuation is
locale-sensitive — French convention inserts a space before the colon
(`" : "`), and a right-to-left locale would need the caption/path order and
punctuation to mirror rather than simply concatenate left-to-right — and
the component does nothing to account for either.

