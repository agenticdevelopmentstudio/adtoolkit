
Follow New Items gives a scrolling list the classic "tail" behavior. While the viewport rests at the edge where the newest row is rendered (within `PIN_SLACK_PX` = 24 px), every change to the rendered list and every resize of the scroll container re-pins the viewport to that edge, so a newly inserted row stays in view wherever in the order it lands. Once the reader scrolls away from the edge they are left alone, and rows inserted above a scrolled-away viewport do not move the row they are reading: the behavior measures that row (the "anchor") and compensates the scroll offset by exactly the distance it shifted.

The concept also defines an at-edge predicate: a pure function that decides whether a container rests at a given edge. Follow New Items produces no return value; its only effects are writes to the scroll container's scroll offset. In the status board it is used by the activity panel and by the shared pane shell, which passes no keys when following is switched off.

