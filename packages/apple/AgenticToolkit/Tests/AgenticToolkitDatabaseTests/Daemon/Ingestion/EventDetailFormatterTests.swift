import XCTest
@testable import AgenticToolkitDatabase

final class EventDetailFormatterTests: XCTestCase {

    // MARK: - SessionStart

    func testSessionStartDetail() {
        let hookData: [String: Any] = [
            "cwd": "/Users/me/projects/myapp",
            "model": "claude-sonnet-4-6"
        ]
        let detail = computeDetail(eventType: "SessionStart", hookData: hookData)
        XCTAssertTrue(detail.contains("myapp"), "Should include project name")
        XCTAssertTrue(detail.contains("claude-sonnet-4-6"), "Should include model")
    }

    func testSessionStartDetailEmptyModel() {
        let hookData: [String: Any] = ["cwd": "/projects/foo"]
        let detail = computeDetail(eventType: "SessionStart", hookData: hookData)
        XCTAssertEqual(detail, "foo")
    }

    // MARK: - PreToolUse

    func testPreToolUseReadDetail() {
        let hookData: [String: Any] = [
            "tool_name": "Read",
            "tool_input": ["file_path": "/path/to/Foo.swift"] as [String: Any]
        ]
        let detail = computeDetail(eventType: "PreToolUse", hookData: hookData)
        XCTAssertTrue(detail.hasPrefix("Read"), "Should start with tool name")
        XCTAssertTrue(detail.contains("Foo.swift"), "Should include filename")
    }

    func testPreToolUseBashDetail() {
        let hookData: [String: Any] = [
            "tool_name": "Bash",
            "tool_input": ["command": "swift build"] as [String: Any]
        ]
        let detail = computeDetail(eventType: "PreToolUse", hookData: hookData)
        XCTAssertTrue(detail.hasPrefix("Bash"))
        XCTAssertTrue(detail.contains("swift build"))
    }

    func testPreToolUseGlobDetail() {
        let hookData: [String: Any] = [
            "tool_name": "Glob",
            "tool_input": ["pattern": "**/*.swift"] as [String: Any]
        ]
        let detail = computeDetail(eventType: "PreToolUse", hookData: hookData)
        XCTAssertTrue(detail.contains("**/*.swift"))
    }

    func testPreToolUseUnknownToolNoInput() {
        let hookData: [String: Any] = [
            "tool_name": "CustomTool",
            "tool_input": [String: Any]()
        ]
        let detail = computeDetail(eventType: "PreToolUse", hookData: hookData)
        XCTAssertEqual(detail, "CustomTool")
    }

    // MARK: - PostToolUseFailure

    func testPostToolUseFailureDetail() {
        let hookData: [String: Any] = [
            "tool_name": "Bash",
            "error": "command not found"
        ]
        let detail = computeDetail(eventType: "PostToolUseFailure", hookData: hookData)
        XCTAssertTrue(detail.hasPrefix("Bash"))
        XCTAssertTrue(detail.contains("command not found"))
    }

    // MARK: - UserPromptSubmit

    func testUserPromptSubmitDetail() {
        let hookData: [String: Any] = ["prompt": "Help me refactor this function"]
        let detail = computeDetail(eventType: "UserPromptSubmit", hookData: hookData)
        XCTAssertEqual(detail, "Help me refactor this function")
    }

    func testUserPromptSubmitLongPromptTruncated() {
        let long = String(repeating: "x", count: 100)
        let hookData: [String: Any] = ["prompt": long]
        let detail = computeDetail(eventType: "UserPromptSubmit", hookData: hookData)
        XCTAssertLessThanOrEqual(detail.count, 80)
    }

    // MARK: - Stop

    func testStopDetail() {
        let hookData: [String: Any] = ["cwd": "/Users/me/projects/stenographer"]
        let detail = computeDetail(eventType: "Stop", hookData: hookData)
        XCTAssertEqual(detail, "stenographer")
    }

    // MARK: - Notification

    func testNotificationDetail() {
        let hookData: [String: Any] = ["message": "Build succeeded"]
        let detail = computeDetail(eventType: "Notification", hookData: hookData)
        XCTAssertEqual(detail, "Build succeeded")
    }

    func testNotificationLongMessageTruncated() {
        let long = String(repeating: "x", count: 100)
        let hookData: [String: Any] = ["message": long]
        let detail = computeDetail(eventType: "Notification", hookData: hookData)
        XCTAssertLessThanOrEqual(detail.count, 80)
    }

    // MARK: - SubagentStart / SubagentStop

    func testSubagentStartDetail() {
        let hookData: [String: Any] = ["agent_type": "code-reviewer"]
        let detail = computeDetail(eventType: "SubagentStart", hookData: hookData)
        XCTAssertEqual(detail, "code-reviewer")
    }

    func testSubagentStopDetail() {
        let hookData: [String: Any] = [
            "agent_type": "code-reviewer",
            "cwd": "/projects/myapp"
        ]
        let detail = computeDetail(eventType: "SubagentStop", hookData: hookData)
        XCTAssertTrue(detail.contains("code-reviewer"))
        XCTAssertTrue(detail.contains("myapp"))
    }

    // MARK: - Task events

    func testTaskCreatedDetail() {
        let hookData: [String: Any] = ["task_subject": "Implement retry logic"]
        let detail = computeDetail(eventType: "TaskCreated", hookData: hookData)
        XCTAssertEqual(detail, "Implement retry logic")
    }

    // MARK: - File / Worktree events

    func testFileChangedDetail() {
        let hookData: [String: Any] = ["file_path": "/projects/myapp/Sources/Main.swift"]
        let detail = computeDetail(eventType: "FileChanged", hookData: hookData)
        XCTAssertEqual(detail, "Main.swift")
    }

    func testCwdChangedDetail() {
        let hookData: [String: Any] = ["new_cwd": "/projects/new-dir"]
        let detail = computeDetail(eventType: "CwdChanged", hookData: hookData)
        XCTAssertEqual(detail, "new-dir")
    }

    func testWorktreeCreateDetail() {
        let hookData: [String: Any] = ["name": "feature-branch"]
        let detail = computeDetail(eventType: "WorktreeCreate", hookData: hookData)
        XCTAssertEqual(detail, "feature-branch")
    }

    // MARK: - Unknown event type

    func testUnknownEventTypeReturnsEmpty() {
        let detail = computeDetail(eventType: "SomeFutureEvent", hookData: ["cwd": "/tmp"])
        XCTAssertEqual(detail, "")
    }

    // MARK: - eventToolInputSummary

    func testToolInputSummaryRead() {
        let result = eventToolInputSummary(tool: "Read", input: ["file_path": "/path/to/MyFile.swift"])
        XCTAssertEqual(result, "MyFile.swift")
    }

    func testToolInputSummaryBashLong() {
        let long = "echo " + String(repeating: "a", count: 100)
        let result = eventToolInputSummary(tool: "Bash", input: ["command": long])
        XCTAssertLessThanOrEqual(result.count, 60)
        XCTAssertTrue(result.hasSuffix("…"))
    }

    func testToolInputSummaryGrepWithPath() {
        let result = eventToolInputSummary(tool: "Grep", input: ["pattern": "func main", "path": "/src"])
        XCTAssertTrue(result.contains("func main"))
    }

    func testToolInputSummaryUnknownTool() {
        let result = eventToolInputSummary(tool: "FutureTool", input: ["key": "value"])
        XCTAssertEqual(result, "")
    }
}
