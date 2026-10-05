
- **Data collected**: This concept collects nothing of its own; it
  operates on whatever archive bytes, expected digest, signature, and
  public key the caller already holds, all of which originate from the
  registry response the caller fetched, not from a person using this
  device.
- **Storage**: Expansion writes the decompressed extension tree to the
  caller-supplied destination, which persists after the call returns by
  design — that is the point of expanding an archive. The scratch location
  used only to expand a signature archive far enough to read its signature
  entry is always removed before the call returns
  (**signature-scratch-cleanup**).
- **Transmission**: None. This concept performs no network I/O.
- **Retention**: This concept is stateless and retains nothing across calls
  (**stateless-namespace**); how long the expanded tree at the destination
  is kept is decided entirely by the caller once expansion returns.

