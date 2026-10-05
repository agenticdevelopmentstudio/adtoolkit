
Not applicable in the sense of user-facing display strings needing
translation infrastructure, but not ideal either: the file-system error
outcome's description text builds every one of its case messages as a
hardcoded English sentence via string interpolation, with no localization
lookup anywhere in the source (**error-description-fixed-strings**). A
caller that surfaces that description directly in UI would show English
text regardless of the user's locale; the workspace layer that is the one
documented caller is itself recorded elsewhere as failing its own
no-hardcoded-strings check for passing these same strings through verbatim.

