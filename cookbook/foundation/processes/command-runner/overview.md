
This component is a namespace holding one entry point — a run-to-completion
operation — that runs a helper process to completion and returns everything
it wrote. It exists to close two ways a synchronous run-and-wait would
otherwise hang forever: an unread output pipe stops the child the moment
the kernel's fixed-size buffer (64 KB) fills, and a tool that never exits
holds the calling thread indefinitely. The run-to-completion operation
installs its own pipe on both the process's standard output and standard
error, drains each continuously as it is written, and waits against a
timeout deadline (or an optional watchdog condition that can end the run
earlier for a reason of the caller's own). A run that reaches its deadline
or its watchdog's condition is terminated — a graceful termination signal,
then a forceful one after a fixed grace period if the process ignores it
— and reported back as an outcome rather than discarded. This is the
whole-output, one-shot shape; a component meant to hold an ongoing
back-and-forth conversation with a child process is a different shape (see
the RPC recipe), which this file does not cover.

