
No string in this component is externalized through a localization key. Every note's `detail` is a hardcoded English string, built by interpolating manifest-supplied values into a fixed English template:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | `declared more than once; the declaration in "<target>" is the one registered.` | A `duplicateViewID` note |
| (none — hardcoded) | `targets the container "<target>", which neither this extension nor this host declares; the pane is arranged along the horizontal axis.` | An `unknownContainer` note |
| (none — hardcoded) | `declares <key> in a form this host cannot read; the pane is offered without it.` | A `malformedField` note |
| (none — hardcoded) | `declares when: <clause>. This host does not evaluate when clauses, so the pane is offered whatever the condition would have said.` | A `whenNotEvaluated` note |
| (none — hardcoded) | `asks for the icon $(<name>), which has no equivalent in this host's symbol set; the pane is offered without an icon.` | An `unmappedIcon` note |
| (none — hardcoded) | `asks for the image <path> from inside the extension; this host does not draw extension image files, so the pane is offered without an icon.` | A `fileIcon` note |

