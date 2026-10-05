
A stateless function that answers which calendar day a UTC instant belongs to in a given IANA time zone. Billing buckets work by the local day in the zone the work happened in, which is stored per segment, not by the UTC day and not by the reader's zone. Every other instant operation (parsing, formatting, canonicalising, arithmetic) belongs to the shared UTC timestamp utility; this holds only the one rule that is billing's own.

