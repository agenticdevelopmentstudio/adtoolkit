
- **Data handled**: Bearer secrets: an access token and a refresh token, plus subscription metadata that identifies the plan.
- **Storage**: The type persists nothing itself; the custody layer stores it in the system keychain.
- **Transmission**: The type transmits nothing itself; it is the payload that crosses a local inter-process boundary between an app and a daemon.
- **Retention**: Held only for the lifetime of the value; callers MUST NOT log it.

