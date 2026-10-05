
`retired-storage.ts` exports one function, `purgeRetiredStorage()`, which deletes browser `localStorage` keys that the status board app no longer reads or writes. Its only entry today is `"adh-activity-v1"`, the activity feed that `use-live-snapshot.ts` used to persist and rehydrate before the board became server-derived. Removing the writer did not remove the data: every browser that loaded the old build still holds a dead blob of several hundred KB. That blob caused a phantom `hub-help-testing` problem that no server-side fix could clear.

Call it once, early, where the board mounts. It is safe during server-side rendering and when storage is unavailable, and it never throws. The package re-exports it from `src/index.ts` (`export * from "./lib/retired-storage"`).

