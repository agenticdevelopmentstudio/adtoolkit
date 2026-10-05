
Not applicable — this class emits no analytics events of its own. Window
interaction tracking for recents is delegated entirely to the window
manager's interaction hook, which itself calls only the platform's own
recent-document API for document windows (a system API, not an analytics
call) and is a documented no-op for non-document windows.

