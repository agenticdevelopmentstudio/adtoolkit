
The two interval algorithms every how-long-was-someone-working measure is built from: splitting activity stamps into runs at idle gaps, and taking the union of overlapping intervals. Both are generic over the stamp type, so epoch seconds (integer or floating point) and fixed-width ISO strings (for the union, which needs only ordering) share one copy. Policy stays with the caller: a lead-in before the first stamp, whether the last run is still open, and what the cutoff is.

