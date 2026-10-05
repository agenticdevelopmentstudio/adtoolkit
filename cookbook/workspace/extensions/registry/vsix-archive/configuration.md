
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| expectedDigest (verification parameter) | an optional string | none — required parameter | The registry-published SHA-256 hex digest to compare the archive against; absent means the registry published none. |
| signature (verification parameter) | optional bytes | none — required parameter | The registry-published signature-archive bytes; absent means no signature was published. |
| publicKeyPEM (verification parameter) | an optional string | none — required parameter | The registry-published Ed25519 public key, PEM-encoded; absent means no key was published. |
| timeout (expansion parameter) | a duration | 120 seconds | How long the extraction utility is given to finish before the run is terminated and reported as timed out. |
| byteCeiling (expansion parameter) | a byte count | 2,147,483,648 bytes | How much allocated disk space may land under the destination before the run is aborted and reported as too large. |
| checkInterval (expansion parameter) | a duration | 0.5 seconds | How often the destination's size is measured against the byte ceiling while extraction runs. |

