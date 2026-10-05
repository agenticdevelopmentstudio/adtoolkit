
- **Decision**: Copy the observed setting's current value directly into
  `isHidden` at the end of `init` (`self.isHidden = self.observer.value`),
  rather than routing the initial state through the same `onChange`
  guard/notify path used for later changes.
  **Rationale**: A synchronous initial assignment prevents the view from
  rendering visible-by-default until the observer's first,
  asynchronously-delivered change notification arrives, and avoids firing
  `onVisibilityChange` for a hosting `GroupView` before that view has even
  finished adding this row — the same reasoning the sibling `ConditionalView`
  recipe (`adtoolkit://cookbook/ui/settings/layout/conditional-view`) documents for its own
  initial-visibility evaluation.
  **Approved**: pending
- **Decision**: Guard the `onChange` handler with `dismissed != self.isHidden`
  before writing `isHidden` or invoking `onVisibilityChange`.
  **Rationale**: Without the guard, any redelivery of the observed setting's
  value would re-trigger a hosting `GroupView`'s separator/padding recompute
  even when this view's own visibility hasn't actually changed.
  **Approved**: pending
- **Decision**: `dismissTapped` unconditionally sets `observer.value = true`,
  with no check of the setting's current value first.
  **Rationale**: The visible-to-dismissed transition only runs one way —
  there is no "undismiss" affordance on the view — so an unconditional write
  costs nothing extra even if tapped on an already-dismissed hint; the
  visibility guard lives in the `onChange` handler, not in the tap handler.
  **Approved**: pending
- **Decision**: Route dismissal through the persisted `dismissedSetting` and
  its `UserSettingObserver`'s asynchronous `onChange` delivery, rather than
  setting `isHidden = true` directly inside `dismissTapped`.
  **Rationale**: This makes "dismissed" a durable, app-restart-surviving fact
  (see Privacy: Storage) instead of transient view state, at the cost of the
  one-main-queue-turn delay between the tap and the view actually hiding
  documented under Edge Cases.
  **Approved**: pending
- **Decision**: Default `buttonTitle` to the English literal `"Got It"`
  rather than requiring every call site to supply a title.
  **Rationale**: Keeps single-hint call sites terse for the common case; see
  Localization for the unlocalized-default consequence this creates for call
  sites that never override it.
  **Approved**: pending

