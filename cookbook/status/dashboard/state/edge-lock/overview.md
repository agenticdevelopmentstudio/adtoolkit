
Edge Lock is a client-only behavior that keeps a scrolling list locked to one edge of its scroll container. Its documentation names the use case: "a list that sits above a details pane", where whatever touches the locked edge rides that edge through every geometry change.

The behavior handles two concerns, and both read and write one tracked geometry record:

- **Container resizes** (split-divider drags, collapse/expand, window resizes). The container's distance from the locked edge (`dist`) is kept exactly the same, every time, whether the list is resting on the edge or scrolled away from it.
- **Item changes** (`newestKey` / `count`). While the container is within `PIN_SLACK_PX` (24 px) of the locked edge, the list follows new content. A reader scrolled further away than that is left where they are.

Edge Lock produces no return value; it works only through side effects on the container element it is given.

