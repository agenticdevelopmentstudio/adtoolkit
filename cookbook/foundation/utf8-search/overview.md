
A substring test that finds a needle's UTF-8 bytes inside a string's own UTF-8 storage with a raw memory search. It is for prefilters that run on every line of a large file: the generic substring search walks indices a character at a time, and on a 130 MB transcript that search was nearly all of the scan. A byte match is exact for any needle, because UTF-8 never lets one character's bytes start inside another's. A hot needle should be held as bytes and passed as such to avoid re-encoding.

