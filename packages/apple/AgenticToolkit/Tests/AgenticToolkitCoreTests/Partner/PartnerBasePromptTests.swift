import Testing
@testable import AgenticToolkitCore

@Suite("PartnerBasePrompt")
struct PartnerBasePromptTests {

    private func job(_ name: String, enabled: Bool) -> PartnerJob {
        PartnerJob(id: "general", name: name, isEnabled: enabled, guidelines: "Be useful.", steps: [])
    }

    @Test func systemPromptHasHeadingForEnabledJobOnly() {
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [
            job("General coding partner", enabled: true),
            job("Sleeper", enabled: false)
        ])
        #expect(prompt.hasPrefix(PartnerBasePrompt.text))
        #expect(prompt.contains("## Job: General coding partner\n\nBe useful."))
        #expect(!prompt.contains("## Job: Sleeper"))
    }

    @Test func systemPromptListsEachEnabledJobsStepsUnderItsHeading() throws {
        var general = job("General coding partner", enabled: true)
        general.steps = [
            PartnerJobStep(name: "open session", environment: .claude, command: "claude {dir}",
                           condition: "the shell prompt is showing")
        ]
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [general])
        let heading = try #require(prompt.range(of: "## Job: General coding partner"))
        let section = String(prompt[heading.upperBound...])
        #expect(section.contains("1. open session (Claude Code prompt): `claude {dir}`"))
        #expect(section.contains("when the shell prompt is showing"))
    }

    @Test func onlyCodeReviewStepsSayTheyArriveFilledFromReviewStart() {
        let line = "arrive filled in from `partner_review_start`"
        var reviews = PartnerJobDefaults.codeReviews()
        reviews.isEnabled = true
        var general = PartnerJobDefaults.general()
        general.isEnabled = true
        #expect(PartnerBasePrompt.systemPrompt(jobs: [reviews]).contains(line))
        #expect(!PartnerBasePrompt.systemPrompt(jobs: [general]).contains(line))
    }

    @Test func baseTextForbidsGitOutput() {
        #expect(PartnerBasePrompt.text.contains("Never pass `--output` to a git command"))
    }

    @Test func baseTextNamesEveryToolAndKeyPhrases() {
        let tools = [
            "partner_projects_list", "partner_session_open", "partner_session_list", "partner_session_screen",
            "partner_session_run", "partner_session_wait", "partner_session_interrupt", "partner_session_close",
            "partner_attention_create", "partner_attention_update", "partner_attention_list", "partner_notify",
            "partner_review_next", "partner_review_start", "partner_review_finish"
        ]
        for tool in tools { #expect(PartnerBasePrompt.text.contains(tool), "missing \(tool)") }
        for phrase in ["attention item", "tick", "went idle"] {
            #expect(PartnerBasePrompt.text.contains(phrase), "missing \(phrase)")
        }
    }

    @Test func baseTextCoversButtonMessagesAndItemReplies() {
        let text = PartnerBasePrompt.text
        #expect(text.contains("Resolved: <text>"))
        #expect(text.contains("Confirmed: <text>"))
        #expect(text.contains("carries an item id"))
        #expect(text.contains("close that item with `partner_attention_update`"))
    }

    @Test func skillDescriptionIsYAMLQuoted() {
        let markdown = PartnerBasePrompt.skillMarkdown(for: job("Say \"hi\": a\\b", enabled: true))
        #expect(markdown.contains("description: \"Say \\\"hi\\\": a\\\\b\"\n"))
    }

    @Test func skillMarkdownHasFrontmatter() {
        let markdown = PartnerBasePrompt.skillMarkdown(for: job("General coding partner", enabled: true))
        let head = "---\nname: adkitchen-partner-general\ndescription: \"General coding partner\"\n---\n"
        #expect(markdown.hasPrefix(head))
        #expect(markdown.contains("Be useful."))
    }
}
