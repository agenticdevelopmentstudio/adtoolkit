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

    /// The code-reviews loop. The app crawls and queues before each tick; the partner starts reviews and judges
    /// what each review session's screen says.
    public static let codeReviewsGuidelines = """
        On a tick, the message says how many reviews are queued and running. Call `partner_review_next`, then \
        start reviews with `partner_review_start`, oldest first, while `running` is below `concurrency`. Never \
        start two reviews in one repo.

        A `partner_review_start` result that is skipped (no session, no steps) needs nothing more: the app has \
        already marked it. Otherwise it names the review's session and lists its steps with their placeholders \
        filled. Run them in order in that session: a terminal step's command with `partner_session_run`, and a \
        claude step's prompt text with `partner_session_run` too, typed at Claude Code's prompt. Check each \
        step's condition on the screen before typing it. If the review step's `/code-review` rejects the bare \
        sha as its target, type it again with the range `{sha}^..{sha}` in the sha's place.

        On a session idle event for a review session, read its screen with `partner_session_screen` and decide: \
        the current step is still working (end your turn), it finished (type the next step), the last step \
        finished (call `partner_review_finish` with `done` and a one-paragraph summary of the findings fixed \
        and the findings skipped, and why), or it is stuck or waiting on something you cannot answer (raise an \
        attention item). Answer what Claude Code asks on the way, the trust-this-folder prompt included.

        On a session exited event for a review session that is not finished, call `partner_review_finish` with \
        `failed` and what the screen last showed.

        Never wait on `partner_session_wait` longer than its maximum; end your turn and let the idle event wake \
        you. Nothing is pushed: the fixes stay on the fix branch for the owner to merge.
        """

    public static func codeReviews() -> PartnerJob {
        PartnerJob(
            id: codeReviewsID,
            name: "Code reviews",
            isEnabled: false,
            scheduleSeconds: 1800,
            guidelines: codeReviewsGuidelines,
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
                                   + "Do not push: the fixes stay on {fix_branch} for the owner to merge. "
                                   + "Report what was fixed and what was skipped.",
                               condition: "The review has finished.")
            ],
            isBuiltIn: true)
    }

    public static var all: [PartnerJob] { [general(), codeReviews()] }
}
