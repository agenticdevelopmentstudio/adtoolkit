
- Stopping with a clock earlier than the start yields whatever the shared seconds function returns for that pair; no guard is added here.
- Flagging the same timer twice counts it only when the flag was newly added.
- The stop reads the segment again after closing it; if it vanished in between the call throws `unknownTimer`.

