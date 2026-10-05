
- **Data handled**: Directory paths and the names of the files directly inside the new directory; it never reads file contents.
- **Storage**: None of its own; it only renames the caller's directories.
- **Transmission**: None; it performs no network access.
- **Retention**: A non-empty placeholder is kept at its aside location; the migration never deletes it.

