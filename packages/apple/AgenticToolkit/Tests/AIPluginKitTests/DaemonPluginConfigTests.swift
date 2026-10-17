import XCTest
import Foundation
import AIPluginKit

/// Guards the daemon's plugin-config key convention. These keys namespace a
/// plugin's stored fields/secrets; if two distinct (plugin, field) pairs ever
/// collapsed to the same key, one plugin's credential could overwrite or leak into
/// another's. The percent-encoding of each dynamic component is what prevents that.
final class DaemonPluginConfigTests: XCTestCase {

    func testFieldKeyShapeIsStable() {
        // A plain ASCII id/field stays human-readable; only non-alphanumerics encode.
        XCTAssertEqual(
            DaemonPluginConfig.fieldKey(plugin: "acme", field: "apiKey"),
            "aiplugin.acme.field.apiKey"
        )
    }

    func testReverseDNSIdentifierEncodesItsDots() {
        // A dot is legal in a reverse-DNS id but is also the structural delimiter, so
        // it must be encoded — otherwise it could be mistaken for a segment boundary.
        let key = DaemonPluginConfig.fieldKey(plugin: "com.example.plugin", field: "apiKey")
        XCTAssertEqual(key, "aiplugin.com%2Eexample%2Eplugin.field.apiKey")
        XCTAssertFalse(
            key.replacingOccurrences(of: "aiplugin.", with: "").hasPrefix("com.example"),
            "the identifier's dots must be encoded, not left raw"
        )
    }

    func testDistinctPluginsWithSameFieldGetDistinctKeys() {
        let keyA = DaemonPluginConfig.fieldKey(plugin: "plugin.a", field: "apiKey")
        let keyB = DaemonPluginConfig.fieldKey(plugin: "plugin.b", field: "apiKey")
        XCTAssertNotEqual(keyA, keyB)
    }

    func testDelimiterCollisionIsPrevented() {
        // Without encoding, a dot/"field" sequence in either component could let two
        // different pairs alias to the same key. Encoding makes the boundary between
        // the plugin id and the field key unambiguous.
        //   plugin="x.field.y", field="z"   vs   plugin="x", field="y.field.z"
        // collide if the components are interpolated raw; they must not here.
        let lhs = DaemonPluginConfig.fieldKey(plugin: "x.field.y", field: "z")
        let rhs = DaemonPluginConfig.fieldKey(plugin: "x", field: "y.field.z")
        XCTAssertNotEqual(lhs, rhs, "delimiter ambiguity collapsed two distinct keys into one")
    }

    func testSecretFieldsLedgerKeyNeverCollidesWithAFieldKey() {
        // The per-plugin secret ledger lives alongside the field keys; a plugin that
        // happened to name a field "secretfields" must not collide with the ledger.
        let ledger = DaemonPluginConfig.secretFieldsKey(plugin: "acme")
        let field = DaemonPluginConfig.fieldKey(plugin: "acme", field: "secretfields")
        XCTAssertNotEqual(ledger, field)
        XCTAssertEqual(ledger, "aiplugin.acme.secretfields")
    }

    func testKeysAreDeterministic() {
        // Same inputs → same key on every call (no salting/ordering surprises), so a
        // value written on one request is found on the next.
        XCTAssertEqual(
            DaemonPluginConfig.fieldKey(plugin: "p", field: "f"),
            DaemonPluginConfig.fieldKey(plugin: "p", field: "f")
        )
        XCTAssertEqual(
            DaemonPluginConfig.secretFieldsKey(plugin: "p"),
            DaemonPluginConfig.secretFieldsKey(plugin: "p")
        )
    }
}
