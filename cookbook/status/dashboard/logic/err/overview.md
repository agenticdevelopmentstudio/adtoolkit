
The error-message operation is a one-line pure function. Its doc comment states its whole contract: "Render an unknown thrown value as a display string (Error → message, else String)." Some runtimes let a caught value be of an unconstrained type; the operation narrows any such value to a string a caller can show.

Every caller in the package uses it inside error handling to build a user-visible error string, some prefixing situational context such as "Auto-configure failed: ", "Match failed — " or "Ignore failed — ". The operation owns no state, performs no I/O, and has no side effects.

