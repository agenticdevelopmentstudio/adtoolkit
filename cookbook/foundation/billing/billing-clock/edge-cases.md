
- An unparseable instant yields an empty day, not an error; callers that group by day must tolerate an empty key.
- A zone identifier that is valid but differs in case from the IANA name is treated as unrecognised if the platform rejects it, and so buckets as UTC.
- An instant exactly at local midnight belongs to the new day.

