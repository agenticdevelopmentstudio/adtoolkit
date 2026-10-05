
Not applicable: none of the three utilities calls any logging API. The debouncer's own contract states this explicitly for itself — it never logs; whoever owns the work owns how a failure is reported — and reports a failure only through the caller-supplied `onFailure` closure, which MAY log but is not required to.

