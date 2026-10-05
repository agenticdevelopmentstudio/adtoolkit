
Not applicable — this is a secure-storage-backed secret-storage interface
and its production implementation, not a visual component. Its only
stateful behavior is the deletelegacy-caller-serialization requirement
above, which is a concurrency contract, not a visual or lifecycle state.

