
This logic computes progress over the current build "cohort" — the set of builds seen in flight since the last all-idle moment. A build joins the cohort while the board reports it in flight (a row with `kind === "deploy"`, `step === "build"` and `tone === "progress"`) and counts as completed once the board stops saying so: the row settles, the server expires it to `"stale"`, or it drops out of the feed. This logic has no clock of its own for judging a build; the only timer it runs is the 2-second hold at 100% after every cohort build is done, after which the cohort resets and the bar hides.

The caller passes its env-filtered activity, so a filtered-out environment's build does not count; the value drives the build-progress bar view. This logic reads nothing but its argument and performs no I/O.

