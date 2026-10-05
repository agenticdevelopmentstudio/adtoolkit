
Not applicable: none of `build.ts`, `route-key.ts`, or `shared.ts` contains a logging call at any level, including on `zodJson`'s caught-exception path (zod-json-fallback-on-throw), which returns its fallback silently.

