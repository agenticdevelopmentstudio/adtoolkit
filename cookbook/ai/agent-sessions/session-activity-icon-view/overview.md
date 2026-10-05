
This is the single glyph a session list row shows at the end of its header line
to say what that session is doing right now: chasing arrows while the agent is
working, a pulsing exclamation badge while it is waiting on the user, sparkles
while a summarization is running over the session, or nothing at all while the
session is simply idle. It owns a small, fixed-size (13×13pt) glyph layer that
it recolors and animates in place as its activity state is updated on every
poll of the session list, rather than being torn down and rebuilt, so a running
spin or pulse survives repeated polling without stuttering.

