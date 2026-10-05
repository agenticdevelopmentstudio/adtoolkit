
- **contains-bytes**: The test MUST report whether the string's UTF-8 bytes contain the needle's bytes as a contiguous run.
- **empty-needle**: An empty needle MUST be contained in every string, including the empty string.
- **empty-haystack**: A non-empty needle MUST NOT be found in an empty string.
- **exact-for-any-needle**: The match MUST be byte-exact and therefore correct for any needle, including multi-byte characters, with no normalization, case folding or locale.
- **string-needle-overload**: A needle given as a string MUST behave exactly as the same string's UTF-8 bytes given as the byte form.
- **hot-path-bytes**: Callers with a hot needle SHOULD hold it as a byte array and pass that form, so the needle is encoded once.
- **no-copy-of-contents**: The search MUST run on the string's own contiguous storage and MUST NOT build an intermediate character array.

