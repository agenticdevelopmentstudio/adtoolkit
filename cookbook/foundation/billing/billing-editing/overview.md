
The billing records (client, project, repo, entry) are immutable, so an edit is a copy with some fields changed. This component supplies those copies, the hand-edit repricing that keeps an entry's amount consistent with the rollup arithmetic, validated parsing of a typed hourly rate, and the display titles used by lists and choosers: a placeholder for a blank name and disambiguated project labels. The creation and update stamps belong to the daemon and are never offered for editing.

