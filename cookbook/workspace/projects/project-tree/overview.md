
This turns a flat registry of repository rows into the hierarchy the
project chooser draws: folders on the way to a project, and the projects
themselves. A tree node is the row type — a folder when it holds no
repository, a project when it holds one — and the builder is the
operation that builds and sorts a forest of those rows from the registry
and a home directory. Paths inside the caller's home directory are shown
relative to it, "so the top of the list is `Development` and
`Deployments` rather than three levels of `Users/<name>` that are the same
for everything" (source documentation); a path outside home keeps its
leading slash, "the only thing distinguishing `/opt` from a folder of the
user's called `opt`". The one caller in the given sources is the project
browser, which builds the tree from the current registry and exposes the
returned roots and every node's `children` directly to its outline view
as its data source.

