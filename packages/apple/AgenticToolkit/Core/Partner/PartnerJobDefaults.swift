import Foundation

/// The two jobs every install starts with.
public enum PartnerJobDefaults {
    public static let generalID = "general"
    public static let codeReviewsID = "code-reviews"

    public static func general() -> PartnerJob {
        PartnerJob(
            id: generalID,
            name: "General",
            isEnabled: true,
            scheduleSeconds: nil,
            guidelines: "Help with whatever the owner asks. Use the session tools to open, read and drive "
                + "Claude Code sessions, and raise attention items rather than waiting on the owner.",
            steps: [
                PartnerJobStep(name: "open session", environment: .terminal, command: "claude",
                               condition: "A fresh tab in the chosen project.")
            ],
            isBuiltIn: true)
    }

    /// Guidelines are filled in by the code-review task.
    public static func codeReviews() -> PartnerJob {
        PartnerJob(
            id: codeReviewsID,
            name: "Code reviews",
            isEnabled: false,
            scheduleSeconds: 1800,
            guidelines: "",
            steps: [
                PartnerJobStep(name: "open session", environment: .terminal,
                               command: "claude --model {model} --dangerously-skip-permissions",
                               condition: "A fresh tab in the review worktree."),
                PartnerJobStep(name: "review", environment: .claude, command: "/code-review high {sha}",
                               condition: "Claude Code is at its prompt; no review already running in this repo."),
                PartnerJobStep(name: "fix", environment: .claude,
                               command: "Fix every finding that still applies at the tip. Skip findings whose code "
                                   + "the later commits ({superseded}) already changed or removed, and say which. "
                                   + "Commit on {fix_branch} with the trailer \"Reviewed-Commit: {sha}\". "
                                   + "Report what was fixed and what was skipped.",
                               condition: "The review has finished.")
            ],
            isBuiltIn: true)
    }

    public static var all: [PartnerJob] { [general(), codeReviews()] }
}
