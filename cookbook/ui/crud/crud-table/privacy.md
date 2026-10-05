
- **Data handled**: Whatever row values the caller passes in `rows`, which MAY include personal or sensitive fields; the component renders them as text and does not inspect them.
- **Storage**: None; the component holds no state of its own.
- **Transmission**: None; it performs no network call.
- **Retention**: None; rows live only as long as the caller's props.

