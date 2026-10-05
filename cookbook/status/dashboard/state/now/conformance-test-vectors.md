
No dedicated test file exists for this concept; it is exercised only indirectly by the board state's own tests (whose fixtures use the live clock because staleness is judged through Now). The vectors below are derived from the source and assume a controllable system clock and timer.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-now-001 | signature, return-unit, mount-snapshot | System clock at 1,000,000; start using Now with the default interval | Returns `1000000` |
| use-now-002 | stable-between-ticks | After use-now-001, advance the clock to 1,010,000 without firing the timer; read the value again | Still returns `1000000` |
| use-now-003 | default-interval, periodic-refresh, no-immediate-refresh | Clock at 1,000,000; start using Now with the default interval; advance the timer by 29,999 ms, then by 1 ms more | Value is `1000000` after 29,999 ms; becomes `1030000` after 30,000 ms |
| use-now-004 | periodic-refresh | Start using Now with a 1,000 ms interval at clock 0; advance the timer by 3,000 ms | Value updates three times, ending at `3000` |
| use-now-005 | interval-change-restart, single-timer | Start using Now with a 1,000 ms interval at clock 0; at 500 ms change the interval to 5,000 ms; advance to 1,000 ms | No update at 1,000 ms; value still `0`; exactly one timer pending; next update at 5,500 ms |
| use-now-006 | unmount-cleanup | Start using Now with a 1,000 ms interval; stop using it; advance the timer by 5,000 ms | The timer is cleared exactly once; no further update or warning occurs; zero pending timers |
| use-now-007 | instance-independence | Start using Now in two places: one with a 1,000 ms interval at clock 0, another at clock 400 | The first returns `0`, the second returns `400`; after advancing to 1,000 ms the first returns `1000` while the second still returns `400` |
| use-now-008 | no-side-effects-beyond-timer | Start using Now with the default interval, with network, storage and logging calls monitored | No calls to any of them |
| use-now-009 | client-only | Load Coarse Clock in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

