
No reference implementation calls a logger, a console-output function, or
any platform logging API. Every failure this component detects is surfaced
to its caller as a thrown domain error; any logging of that failure is the
responsibility of the caller or host application, not of this domain
component.

