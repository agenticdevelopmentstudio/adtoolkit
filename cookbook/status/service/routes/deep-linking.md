
`POST /auth/device` constructs a `verification_uri` that a client renders as
a link (or QR code) to complete the device-authorization flow in a browser;
this is the one place in these 17 files that manufactures a URL meant to be
followed by a human outside the calling client. No other route in this
component constructs or consumes a deep link — the remaining 16 files are
JSON/SSE/SVG APIs with no link surface.

