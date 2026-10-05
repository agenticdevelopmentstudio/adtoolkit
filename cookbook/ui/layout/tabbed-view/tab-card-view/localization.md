
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — | "Close" | The close control's icon's accessibility label |

"Close" is a hardcoded English string literal passed directly as the
accessibility label, not routed through any localization mechanism used in
this component. (The status symbols' accessibility labels, and every label's
displayed text, are caller-supplied data from the data source and
status-symbol values — like a tab's own title in the tabbed-view recipe,
they carry no localization concern of this component's own making.)

