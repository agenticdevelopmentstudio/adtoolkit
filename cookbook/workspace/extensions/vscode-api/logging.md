
Subsystem: matches the host's logging subsystem | Category: the bridge's own category

| Event | Level | Trigger |
| --- | --- | --- |
| oversized-array refusal | error | reading an array-like value's length refuses one whose length exceeds the maximum decodable array length |
| error-construction failure | error | raising an exception finds that building a fresh error value for the given message failed |
| malformed trampoline record | error | reading a dispatch outcome finds the settled dispatch value is not an object, or its success flag is missing or not a boolean |
| trampoline install failure | error | installing the shared trampoline helper cannot evaluate or cache its source in a context |
| sub-namespace factory install failure | error | installing the sub-namespace factory cannot evaluate or cache its source in a context |

