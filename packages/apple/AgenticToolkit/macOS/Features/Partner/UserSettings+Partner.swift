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
}
