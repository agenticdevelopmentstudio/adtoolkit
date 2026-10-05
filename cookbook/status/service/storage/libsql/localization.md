
Not applicable: this storage layer emits no user-facing string. Every text value it defines (`'healthy' | 'degraded' | 'down'`, platform-id prefixes, `'pending' | 'viewer' | 'admin'`, and so on) is an internal enum literal or SQL identifier consumed by other backend code, never displayed directly.

