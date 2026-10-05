
Every user-facing string in this component is a hardcoded English literal — there
is no localization-catalog reference or i18n library call anywhere in the given
implementation files. Representative examples: the user-auth topic's "When off, no
one can sign in to this ecosystem."; the sign-up-mode help text's three case
strings; the feature-flags and server-bags removal messages; the origin-validation
step's four rejection messages; the storage-tokens rail's name-taken, create-failed,
and about-text messages. This is a fact of the current implementation, not a gap
this recipe marks — nothing in the source suggests localization is planned or
partially wired.

