
Not applicable: this component makes no logging call of any kind; its only
failure path (reading a directory's contents failing) is caught and
discarded with no log output — see the pending decision on
`unreadable-directory-error-visibility`.

