
Not applicable: this component makes no logging call of its own; failures
inside the operations it delegates to are logged by the secure-storage
helper's own get/set operations, a dependency of this component, not a call
this component makes itself.

