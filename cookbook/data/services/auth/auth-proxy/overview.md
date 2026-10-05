
This recipe is the server half of a site's authentication plumbing: a
Backend-for-Frontend (BFF) that forwards a browser's `/api/*` and `/auth/*`
requests to the shared backend from a server-side request handler, rather
than a declarative rewrite rule. It exists specifically because a
declarative rewrite cannot preserve auth on every hosting tier: one hosting
target (OpenNext running on Cloudflare Workers) issues its outbound request
with automatic redirect-following by default, which silently follows the
backend's OAuth redirect and discards its `Set-Cookie` header. This module
forces manual redirect handling so a 3xx response (and its `Set-Cookie`)
reaches the browser unmodified. Sites that proxy via a declarative rewrite
(such as on Vercel) don't need it. A consuming site wires it into three
exported request handlers on its own catch-all route, forwarding whatever
method it receives.

It is a headless **logic** module — no visual surface — so this recipe marks
Appearance, States and Accessibility not applicable and carries the runtime
contract entirely in Behavioral Requirements, per the non-UI component
guidance this recipe was authored under.

