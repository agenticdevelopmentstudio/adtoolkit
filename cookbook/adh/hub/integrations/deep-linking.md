
| Platform | URL Pattern |
|----------|-------------|
| Web | `/integrations/oauth-callback` — the fixed landing route for a provider's OAuth/app-install redirect; the callback-URL builder returns the full redirect URI as `<page origin><callback path>`. |

This component's source only defines a web route; no Apple or Android route is defined here. A future
Apple or Android port would need its own equivalent redirect-landing registration (a custom URL scheme
or an associated-domains universal link on Apple, an App Link/deep link intent filter on Android) —
none of which exists in this checkout to describe.

