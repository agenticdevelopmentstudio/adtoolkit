
Window Activation is a logic package that tries to bring a specific
terminal window (identified by process, project name, working directory and
the `$TERM_PROGRAM` value) to the front, and records a detailed diagnostic log of how it
did so. It is intended for developer and QA use to diagnose why a terminal
window will not come to the front.

The package consists of:

- **a window-activation target** — an app-agnostic value describing the window to activate.
- **the activation-strategy contract** — the interface for one step of the activation cascade.
- Three built-in strategies: **the iTerm TTY strategy**, **the accessibility title-match strategy**, **the bring-terminal-to-front strategy**.
- **the terminal catalog** — the catalog of terminals matched by the `$TERM_PROGRAM` value, made of individual catalog entries.
- **the running-applications provider** / **the real running-applications provider** — a narrow abstraction over the running-application list, injectable for tests.
- **the TTY resolver** (internal) — resolves a PID's controlling TTY by running `ps`.
- **the activation test log** — a thread-safe, append-only, timestamped log mirrored to memory and optionally a file.
- **the activation test harness** — runs the cascade over a list of targets, verifies the frontmost window after each, and returns pass/fail counts.

Use it when an app (for example the Session Watcher list) needs to raise the
terminal window that owns a session and wants a written trace of each attempt.

