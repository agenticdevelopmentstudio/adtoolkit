// Core/Chat/ToolJSONSchema.swift
import Foundation

/// Builds the `parametersJSONSchema` of a `ToolDefinition`. One place, so
/// every tool source spells an object schema the same way.
public enum ToolJSONSchema {
    /// `properties` maps a name to its schema fragment, e.g.
    /// `["url": ["type": "string", "description": "…"]]`.
    public static func object(properties: [String: [String: Any]], required: [String] = []) -> Data {
        let object: [String: Any] = ["type": "object", "properties": properties, "required": required]
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data("{}".utf8)
    }

    public static func string(_ description: String) -> [String: Any] {
        ["type": "string", "description": description]
    }
    public static func integer(_ description: String) -> [String: Any] {
        ["type": "integer", "description": description]
    }
    public static func number(_ description: String) -> [String: Any] {
        ["type": "number", "description": description]
    }
    public static func boolean(_ description: String) -> [String: Any] {
        ["type": "boolean", "description": description]
    }
}
