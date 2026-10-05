
Field sync is the single policy a record pane follows when it puts stored
values back into its editable fields, for every pane that shows a record
which can change underneath it. It has two modes. A refresh (`load`) shows
the stored value unless the user is in the middle of editing that field, so a
background poll that lands mid-word never replaces what is being typed. A
forced revert (`force`) is used after a save that was refused: the text in the
field is exactly what failed, so it is discarded, including any edit session
in progress, so that ending the edit later cannot send the refused text again.
It also provides one helper that selects a pop-up item by the value it
represents rather than by its title.

