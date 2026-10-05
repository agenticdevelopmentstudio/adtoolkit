
- **Data collected**: None from the user. The adapter stores the telemetry snapshot the dashboard already fetched: grouped error issues (`project`, `title`, `culprit`, `level`, counts, timestamps, `permalink`) and anonymous aggregate analytics KPIs (`metric`, `window`, `scope`, `value`).
- **Storage**: Plain-text JSON in the browser's `localStorage` for the dashboard's origin, under `adh-telemetry-v1`; not encrypted, readable by any script running on that origin.
- **Transmission**: None. The adapter never sends the snapshot anywhere.
- **Retention**: Until the next `save` overwrites it or the browser clears the origin's site data; the adapter never deletes or expires it.

