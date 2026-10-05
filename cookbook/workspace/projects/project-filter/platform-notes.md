
- **SwiftUI**: The source
  (`packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectFilter.swift`,
  tests `Tests/AgenticToolkitMacOSTests/Projects/ProjectFilterTests.swift`)
  imports only `Foundation` — no AppKit, UIKit, or SwiftUI dependency — so it
  ports unchanged into a SwiftUI-hosted app. A SwiftUI list would call
  `ProjectFilter.matches(_:query:)` inside its data source's `filter` and
  `ProjectFilter.ranges(of:in:)` to build an `AttributedString` with bolded
  matched runs for each row, exactly as `ProjectBrowserViewController` does
  today with `NSAttributedString`.
- **Compose**: Model `ProjectFilter` as a Kotlin `object` with `fun
  ranges(query: String, text: String): List<IntRange>` and `fun
  matches(repo: GitRepo, query: String): Boolean`. Kotlin's `String` has no
  UTF-16-`NSRange`-shaped search API, so implement the scan with
  `text.indexOf(query, startIndex = start, ignoreCase = true)` in the same
  left-to-right loop, breaking on `-1` and advancing
  `start = index + maxOf(query.length, 1)` to reproduce
  `non-overlapping-scan-advance`; because `indexOf` performs a literal
  search, `literal-substring-matching` carries over with no extra work.
- **React/Web**: Model the two functions as `rangesOf(query: string, text:
  string): Array<[number, number]>` and `matchesRepo(repo: GitRepo, query:
  string): boolean`, using `text.toLowerCase().indexOf(query.toLowerCase(),
  start)` in the same loop (JavaScript strings are UTF-16-indexed, so the
  returned `[start, length]` pairs line up with the Swift `NSRange`
  coordinates directly, satisfying `utf16-range-coordinates` with no
  conversion). Render matches by slicing `text` at the returned pairs into
  bold/`<mark>` spans, mirroring `ThemedHighlightLabel`'s role.
- **AppKit / UIKit**: This is the file's actual runtime home today.
  `ProjectBrowserViewController.applyFilter()` calls
  `ProjectFilter.matches(_:query:)` to decide which `GitRepo` rows survive
  into the `NSOutlineView`-backed project tree, and `ProjectRowView` calls
  `ProjectFilter.ranges(of:in:)` to bold matched characters in each row's
  `ThemedHighlightLabel`. `BreadcrumbPopoverViewController.applyFilter()`
  and `attributedTitle(for:)` reuse the same two functions to filter and
  bold-highlight an `NSTableView`'s rows. Nothing in `ProjectFilter.swift`
  itself is AppKit-specific — `NSRange`/`NSString` are equally available
  under UIKit, so it ports unchanged.
- **WinUI 3**: This is the platform this recipe exists to steer. Model
  `ProjectFilter` as a static class with `public static IReadOnlyList<(int
  Location, int Length)> Ranges(string query, string text)` and `public
  static bool Matches(GitRepo repo, string query)`. .NET `string` is
  already UTF-16-indexed the same way `NSString` is, so
  `text.IndexOf(query, start, StringComparison.OrdinalIgnoreCase)`
  reproduces `case-insensitive-matching` and `literal-substring-matching`
  directly (`IndexOf` never treats `query` as a pattern), and the same
  `start = index + Math.Max(query.Length, 1)` advance reproduces
  `non-overlapping-scan-advance` with no coordinate conversion needed.
  Bind the returned ranges to a `TextBlock`'s `Inlines` — a bold `Run` per
  matched range and a regular `Run` for the gaps between them — inside the
  `ItemsRepeater`/`TreeView` `DataTemplate` that lists projects, and filter
  the bound `ObservableCollection<GitRepo>` with `Matches` from the search
  box's `TextChanged` handler, mirroring `applyFilter()`'s role.

