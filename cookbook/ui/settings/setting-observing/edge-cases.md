
- **Null/empty input**: Not applicable: the contract is generic over its value type; it adds no null handling of its own.
- **Boundary values**: Not applicable: no value range is defined by the contract.
- **Concurrent access**: The contract is main-thread only. A write issued from another thread is outside it.
- **Error states**: Not applicable: neither read nor write can report a failure; a failing source is the source's concern.
- **Offline/disconnected state**: Not applicable: the component performs no networking.
- **Callback replaced after write**: A callback assigned after a write is queued but before it drains is the one that fires, because the callback is read when the delivery runs.

