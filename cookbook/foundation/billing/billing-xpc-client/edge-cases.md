
- A body that cannot be encoded never leaves the process.
- A read that times out is treated as nil, indistinguishable from other failures.
- A write sent but not answered within the bound may still commit on the daemon; the bound exists to make that rare.
- The overview and the preferences push have their own failure shapes (nil and false), not refusals.

