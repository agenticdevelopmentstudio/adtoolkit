import Foundation
import AgenticToolkitCore

/// The Coding Partner's preferences. Keys are namespaced `partner.`.
@MainActor
extension UserSettings {

    /// Whether the partner runs at all.
    public static let partnerEnabled = UserSetting<Bool>("partner.enabled", default: false)

    /// The model passed to `claude --model`; "" = Claude Code's own default.
    public static let partnerModel = UserSetting<String>("partner.model", default: "")

    /// The `--permission-mode` the partner's Claude Code runs under.
    public static let partnerPermissionMode = UserSetting<String>("partner.permission_mode", default: "dontAsk")

    /// Space-separated `--allowedTools` entries: the partner's MCP tools plus read-only git and Read.
    public static let partnerAllowedTools = UserSetting<String>(
        "partner.allowed_tools",
        default: "mcp__adkitchen Bash(git log *) Bash(git show *) Bash(git diff *) Bash(git status *) "
            + "Bash(git branch *) Read"
    )

    /// How long a session's output must be quiet before the partner is told it went idle.
    public static let partnerIdleSettleSeconds = UserSetting<Int>("partner.idle_settle_seconds", default: 60)

    /// How long one partner turn may run before it is timed out.
    public static let partnerTurnTimeoutMinutes = UserSetting<Int>("partner.turn_timeout_minutes", default: 15)

    /// Whether the partner window floats above other windows.
    public static let partnerAlwaysOnTop = UserSetting<Bool>("partner.window_always_on_top", default: false)

    /// Whether the Needs-you pane is shown in the partner window.
    public static let partnerAttentionPaneVisible = UserSetting<Bool>("partner.attention_pane_visible", default: true)

    /// How many days done attention items stay in the window.
    public static let partnerAttentionRetentionDays = UserSetting<Int>("partner.attention_retention_days", default: 7)

    /// The attention kinds that also post a macOS notification.
    public static let partnerNotifyKinds = UserSetting<Set<String>>(
        "partner.notify_kinds",
        default: ["question", "blocked", "notification"]
    )

    // MARK: - Code reviews

    /// How far back, in hours, the crawl looks for commits to review.
    public static let partnerReviewsWindowHours = UserSetting<Int>("partner.reviews_window_hours", default: 24)

    /// How often, in minutes, the code-reviews job crawls for new commits.
    public static let partnerReviewsCrawlIntervalMinutes = UserSetting<Int>(
        "partner.reviews_crawl_interval_minutes", default: 30)

    /// How many reviews may run at once (never more than one per repo).
    public static let partnerReviewsConcurrency = UserSetting<Int>("partner.reviews_concurrency", default: 1)

    /// Whether the crawl covers every local branch, not only the default one.
    public static let partnerReviewsIncludeOtherBranches = UserSetting<Bool>(
        "partner.reviews_include_other_branches", default: false)

    /// The model the reviewer's Claude Code runs (`{model}`); "" = Claude Code's own default.
    public static let partnerReviewsReviewerModel = UserSetting<String>("partner.reviews_reviewer_model", default: "")

    /// The branch each repo's review worktree commits its fixes on.
    public static let partnerReviewsFixBranch = UserSetting<String>(
        "partner.reviews_fix_branch", default: "partner/review-fixes")
}
