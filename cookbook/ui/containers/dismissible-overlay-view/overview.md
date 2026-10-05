
A view that lays a blurred backdrop over another view and blends itself in
and out. Per the concept's own rationale, it exists because two overlays in
the toolkit share the same "manners" though not the same content — "one
conversation lifted out of a merged feed, and one message opened to its full
length" — and those manners (cover the host entirely, fade rather than
appear, and go away on Escape, on Return, or on a press no control took) live
here so a fix to any of them lands in every overlay built on it. A subclass
adds its own content as ordinary subviews above the backdrop and overrides
the pre-dismissal hook for whatever it has running that needs to stop.

