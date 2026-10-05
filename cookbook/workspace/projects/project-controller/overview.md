
The project controller is the one-per-project-window owner of a project's
checkouts and their branch controllers. It decides which tabs the window
shows by reconciling the checkouts git reports against the tabs the
project's stored workspace state holds, and it answers the window's
tab-item requests as the project's tab-item data source. Per its own design
rationale, it "knows nothing about views beyond vending what a branch
controller makes." It serializes its own two entry points (opening, and
refreshing checkouts) onto one chained operation so two overlapping callers
cannot let a slower, earlier git read overwrite a faster, later one, and it
keeps a project's branch-scoped commands registered with the app's command
registry in step with which checkouts currently exist.

