
Media Query is client-only state that reports whether a CSS media query currently matches the viewport. Its contract: it returns false during a server-rendering pass and first paint (the server can't measure the viewport), then updates after its subscription is established and on every change. Callers use it to switch between layouts; in the status dashboard, the overview view evaluates `"(max-width: 760px)"` to pick the mobile layout and the wallboard status view evaluates `"(min-width: 761px)"` to pick the wide layout.

