
Not applicable: none of the three given sources make a logging call (no
`import os`, no `Logger`, no `print` appears in any of them). A failure
surfaces only as a thrown `HubError` as described under Behavioral
Requirements and Edge Cases; if a host wants to log it, that logging
happens outside these sources.

