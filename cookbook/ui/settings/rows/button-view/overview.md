
The Button View is a settings-row control that wraps a single button. Its
title and the action performed on press are both driven entirely by a
caller-supplied view model, not configured on the component itself. It
fulfills the same settings-row-view contract as its siblings in this
system. A placement option controls how the button sits in the row it is
given: stretched across the whole row (fill, the default), sized to its
own title at the row's leading edge (leading), or sized to its own title
and centered in the row (centered).

The view model exposes a `title` (immutable) and an optional
`wasPressedCallback` (mutable, default none) invoked when the button is
pressed; it also carries an `explanation` field common to every view model
in this family, which this component never reads.

