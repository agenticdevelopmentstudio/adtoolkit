
The component shows a directory tree (via a hosted file tree) plus a footer
strip with add/remove controls for adding and removing extra root
directories. It owns one file tree manager per root directory shown (the
primary root plus any the user adds), starts and stops each manager's
filesystem watching in step with the component's own appearance, and forwards
selection and open-file events to a host through shared state (a directories
state, a selection state, a restoration state) and callbacks (an open-request
callback, a pane-selection-change callback). It can be embedded in any
container — a document pane, a sidebar, a window — with no assumptions about
what hosts it.

