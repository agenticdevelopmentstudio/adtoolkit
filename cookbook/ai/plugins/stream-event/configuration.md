
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| data (parameter to consume) | byte payload | none — required | Newly received bytes for the response currently being decoded; MAY be a full frame, a partial frame, or an empty buffer. |
| decoder instance | abstract decoder role | none — required | Supplied per request by the conforming plugin's decoder-construction operation (see the sibling plugin recipe); this component neither creates nor configures a decoder itself. |

This component defines no environment variable and no settings key of its
own — every value it operates on arrives as a parameter, either the raw
bytes handed to consume or the decoder instance itself.

