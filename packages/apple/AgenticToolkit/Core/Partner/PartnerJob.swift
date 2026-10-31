import Foundation

/// One step of a job: what to type, where, and when it is the right moment.
public struct PartnerJobStep: Codable, Sendable, Equatable {
    public enum Environment: String, Codable, Sendable { case terminal, claude }

    public var name: String
    public var environment: Environment
    public var command: String
    public var condition: String

    public init(name: String, environment: Environment, command: String, condition: String) {
        self.name = name
        self.environment = environment
        self.command = command
        self.condition = condition
    }
}

/// A standing piece of work the partner does, on a timer or on request.
public struct PartnerJob: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var isEnabled: Bool
    public var scheduleSeconds: Int?
    public var guidelines: String
    public var steps: [PartnerJobStep]
    public var isBuiltIn: Bool

    public init(id: String, name: String, isEnabled: Bool, scheduleSeconds: Int? = nil,
                guidelines: String, steps: [PartnerJobStep], isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.scheduleSeconds = scheduleSeconds
        self.guidelines = guidelines
        self.steps = steps
        self.isBuiltIn = isBuiltIn
    }
}
