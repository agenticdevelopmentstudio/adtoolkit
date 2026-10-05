
Not applicable: none of these route files emits an analytics event of its
own. `telemetry.ts`'s `GET /analytics` route only serves analytics metrics
that were already captured elsewhere (`storage.telemetry.analytics.load()`);
it does not instrument these routes themselves.

