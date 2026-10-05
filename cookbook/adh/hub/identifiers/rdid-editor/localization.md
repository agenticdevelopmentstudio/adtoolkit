
Every piece of display text (`label`, `placeholder`, `hint`, `error`) is
supplied by the caller as an input; the component defines no string
literals of its own to key or translate.

The one text-processing operation the component performs itself —
**lowercases-input-on-change** — is a casing transform, and casing
transforms are locale-sensitive: the same character can lowercase
differently depending on locale (e.g. Turkish `İ`/`I`). Here that
locale-sensitivity is deliberately not honored: the value being
transformed is an rdid leaf, a machine-readable identifier the backend
re-parses with a fixed, locale-invariant grammar, not user-facing prose,
so it needs to lowercase identically no matter the editing user's
locale. A plain, locale-invariant lowercasing (as opposed to a
locale-aware one) already gives exactly that here, since it applies
Unicode's locale-independent default case folding.

