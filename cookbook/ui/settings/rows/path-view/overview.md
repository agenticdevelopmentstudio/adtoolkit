
The Path View is a settings row: a single label showing one filesystem
path "as a path rather than as prose." It conforms to the settings row
interface every settings row implements, with no requirements of its own.
The design rationale: the sibling row
[Explanation View](adtoolkit://cookbook/ui/settings/layout/explanation-view)
word-wraps, which is right for a sentence and wrong for a path — a real
path wrapped inside a settings panel's ~134pt content column broke across
nine hyphenated lines, long enough to push the group heading off the bottom
of the pane. The Path View instead keeps its label to one line and
truncates in the middle, so the head (where the path lives) and the tail
(which one it is) both survive and only the middle — the part every
sibling path tends to share — is dropped. The full, untruncated path stays
reachable through the label's tooltip and accessibility value, and the
label is selectable so its text can be copied.

