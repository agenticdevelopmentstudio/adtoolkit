
Each site definition carries hardcoded English `label`, `fullLabel`, `shortLabel`,
and `description` strings for every site (for example `"The Agentic Developer Hub"`,
`"Recipes & patterns"`), and header-title derivation's `"Agentic Developer <X>"`
title is built from the same hardcoded English convention. None of these strings is
routed through any localization or string-catalog layer in this component; a
translated build of the switcher, footer, or header would need its own separate
string source, since this registry supplies only the one, English, copy.

