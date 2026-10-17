import Foundation

/// A daemon's storage convention for AI plugin configuration.
///
/// The host app pushes the selected plugin's field values to the daemon; the daemon
/// persists non-secret fields in its settings table and secret fields in its own
/// Keychain namespace under these keys, then resolves them back into an
/// `AIPluginConfig` at completion time. The *wire protocol* (the `fields`/`secrets`
/// maps keyed by descriptor field key) is the cross-process contract — these key
/// strings are an internal daemon detail, so they need only agree with themselves.
public enum DaemonPluginConfig {

    /// Settings-table key holding the identifier of the plugin to complete with.
    /// Empty (or absent) means "use the zero-config claude_cli path".
    public static let selectedPluginKey = "ai_plugin_id"

    /// Storage key for one of a plugin's descriptor fields (secret or plain).
    public static func fieldKey(plugin identifier: String, field key: String) -> String {
        "aiplugin.\(encoded(identifier)).field.\(encoded(key))"
    }

    /// Settings-table key holding the newline-joined descriptor field keys whose
    /// secrets the daemon currently stores for `identifier`. Recorded on write so the
    /// daemon can clear exactly those Keychain entries when the user switches plugins
    /// (it can't enumerate its own secret namespace).
    public static func secretFieldsKey(plugin identifier: String) -> String {
        "aiplugin.\(encoded(identifier)).secretfields"
    }

    /// Percent-encodes a dynamic key component so a dot — legal in a reverse-DNS
    /// plugin identifier — can't be mistaken for one of the structural `.` delimiters.
    /// Two distinct (plugin, field) pairs therefore always map to distinct keys.
    private static func encoded(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? raw
    }
}
