
- A read of a missing record returns nil rather than throwing.
- A host that cannot honor `transaction` atomically cannot satisfy the rollup's no-double-count guarantees.
- Deleting a client detaches its projects; deleting a project detaches its segments; both are the host's to implement.

