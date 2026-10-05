
The component announces a calendar day once, centered above the first message of that day in a chat transcript, and flanked by a horizontal rule on each side. A per-message timestamp says *when in the day* a message was sent; nothing else in a scrolled transcript says *which day* it was, so this banner supplies that context exactly once per day rather than on every message. It is theme-aware — it recolors its label and rules when the active theme's palette changes — and exposes the day it is showing and its rendered title text for a caller that needs to read either back.

