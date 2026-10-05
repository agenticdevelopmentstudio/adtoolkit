
- **base-if-free**: The next name for a base MUST be the base itself when it is not among the taken names (compared exactly).
- **numbered-suffix**: When the base is taken, the next name MUST be the base, a space and the smallest integer from 2 upward whose combined name is not taken (`New Client 2`, `New Client 3`).
- **skips-every-taken-suffix**: The numbering MUST skip every taken suffix and use the first free one, not merely count the taken names.
- **next-compares-exactly**: The next-name search MUST compare names exactly, case and whitespace included.
- **collides-folds**: The collision check MUST compare names after trimming surrounding whitespace and newlines and folding case, and MUST report a collision when any taken name equals the wanted name under that comparison.
- **collides-for-renames**: The collision check is intended for refusing a rename onto another record's name; the caller is responsible for excluding the record being renamed from the taken names.
- **any-sequence**: Both functions MUST accept any sequence of taken names, not only a list.

