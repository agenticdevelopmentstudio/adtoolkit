
Not applicable: no part of this component defines or reads a feature-flag
key. Every conditional path — whether an AS base is configured, whether the
SSO-hint cookie is present, whether the site is cross-apex, whether a
preflight allows a silent restore — is derived from runtime configuration, a
cookie, or a server response, never from a flag this module owns.

