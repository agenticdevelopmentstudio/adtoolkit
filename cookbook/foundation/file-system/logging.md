
This component performs no logging of its own — no logging call or
diagnostic breadcrumb of any kind appears anywhere in its source. Every
failure surfaces as a thrown, typed file-system error outcome instead of a
log line; a caller that wants a trail of what this component did must log
at its own call site.

