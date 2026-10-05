
- **Data handled**: The JSONC preprocessor defines no data field of its
  own — every byte and character it touches is the caller's input, held
  only for the duration of one call. In this repository that data is a VS
  Code style configuration file: a color theme, a language snippet file, or
  an extension's manifest and localization tables — content an extension or
  theme author wrote, not a credential or access token.
- **Storage**: None — the component performs no read or write of its own;
  it returns a transformed value in memory and retains nothing once the
  call returns.
- **Transmission**: None — the component performs no network I/O of its
  own (**no-side-effects**).
- **Retention**: None — no state survives past the return of the call that
  produced it; there is no instance to hold anything between calls.

