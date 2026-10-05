
The settings view presents a project's own settings as a sheet on its parent
window. It is deliberately the same shape as the app's global settings
surface — a topic list on one side, a panel on the other — so that a second
topic is simply another panel added to the list rather than a second dialog.
The view is composed of four parts: the outer sheet chrome (the outer
container and its Done button), the topic list (a split view showing
available topics), and two settings panels — a Tabs panel (four per-edge
tab-bar toggles) and a Spacing panel (two bound spacing controls for frame
and divider spacing). Every change is applied as it is made — there is no
staged state, no commit, and no cancel.

