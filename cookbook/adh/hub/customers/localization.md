
None of the three given sources reference a string-key or localization
table; every user-facing string `CustomersTopic` produces is a hardcoded
English literal composed inline:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no key) | `Users` | `CustomersTopic.entry.label` and the users-list level's `title`. |
| (none — literal, no key) | `The people who sign in to this product.` | `CustomersTopic.entry.description`. |
| (none — literal, no key) | `No users yet.` | Users list level's `emptyMessage`. |
| (none — literal, no key) | `New user` | The list level's `createAction.title`, reused as `FormSheet.present`'s dialog title. |
| (none — literal, no key) | `Enter a valid email address.` | `CustomersTopic.emailMessage`, the shared email field's pattern-mismatch message. |
| (none — literal, no key) | `A user with email "<email>" already exists.` | Create/detail save-action duplicate message (client precheck or server conflict). |
| (none — literal, no key) | `Delete user` | Detail form's delete action `title`. |
| (none — literal, no key) | `Delete user "<label>"? This cannot be undone.` | Detail form's delete confirmation text. |
| (none — literal, no key) | `User` | Detail's fixed `title`. |
| (none — literal, no key) | `Email`, `Display name`, `External ID`, `Handle`, `Avatar URL` | The five shared field labels from `fieldSpec(isRequiredEmail:)`. |

The generic `"<label> is required"` message a blank required field
produces (for example, a blank `email`) belongs to the Forms subsystem's
own validation, documented in the related HTDV Engine recipe, not to any
of this recipe's three given sources.

