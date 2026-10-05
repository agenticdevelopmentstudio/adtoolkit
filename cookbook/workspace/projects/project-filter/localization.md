
Not applicable: this component produces no user-facing string of its
own. It returns a list of ranges and a true/false result; any text the
caller renders (a project's own name, or a static string like "No
projects yet") is built and localized, if at all, by the caller (the
project browser, the breadcrumb popover), not by this component.

