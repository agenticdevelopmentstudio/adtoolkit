
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `coordinator` (construction parameter, also passed to the choose-and-callback entry point) | coordinating-component reference | none — required | Supplies the repository list the hosted project browser lists; never constructed internally. |
| `onChoose` (parameter to the choose-and-callback entry point) | callback taking a repository record | none — required | Called exactly once, with the chosen repository record, when the modal session resolves to a value; never called otherwise. |

This dialog reads no environment variable and no settings key directly.
Quiet presentation, consulted only when activating the application before
showing the window, is a separate concern reached by this file only as an
opaque check (see **runmodal-activation-respects-quiet-presentation**).

