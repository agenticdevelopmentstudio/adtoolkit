
This declares three persisted settings for the Projects feature: a list of
repo-scan skip patterns, stored under the key `projectScanSkipPatterns` and
defaulting to the scanner's own default root skip-pattern list; a flag that
highlights the active pane, stored under the key `highlight_active_pane`
and defaulting to `true`; and a flag that makes pane focus follow the
pointer, stored under the key `active_pane_follows_mouse` and defaulting
to `false`. Each is a plain settings declaration with no logic of its own
— no validation, no side effect beyond what the underlying settings
mechanism already provides.

This file declares no read, write, remove, or observe mechanics of its
own; a shared settings-storage layer supplies that behavior, and a shared
storage provider supplies the persistence mechanics. This recipe covers
those collaborators only for the contract they give these three settings —
their own general contract belongs to a collaborator's own recipe (the
[Git Repo Scanner](adtoolkit://cookbook/workspace/projects/git-repo-scanner)
recipe already covers the scanner that consumes the skip-patterns
setting). The code that reads the skip-patterns setting and constructs a
scanner from it, the settings panel that edits all three, and the
per-project override that can supersede the active-pane-highlight setting
are likewise collaborators' own contracts, out of scope here except where
this file's own documentation makes a claim about them.

