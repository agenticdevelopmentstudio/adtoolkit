
- A decoder that cannot read a body yields the nil-with-reason write reply, never a crash.
- A DTO per selector is deliberately avoided: it would need a secure-coding class per DTO.
- The protocol declares only billing; a daemon's other selectors live in its own protocol.

