
This is a modal for sending invitations over email and/or SMS. It composes a dialog
shell, a recipient-list input, a note field, a discard-confirmation alert, and a send
button. It is invoked with seed lists of emails/phones from a recipient selection made
elsewhere in the caller's app. The actual send is delegated entirely to a
caller-supplied send callback.

It is a controlled dialog with up to two sections — **SMS** and **Email** — each
shown only when its seed list is non-empty. Each section displays a read-only
recipient list and an optional admin note. The footer cancels (with confirm if
populated) or sends.

