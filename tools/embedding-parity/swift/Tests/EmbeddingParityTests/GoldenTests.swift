// Checks the Swift embedder against a bundle's golden set: the same prefixed
// text, identical token IDs, and a vector whose cosine against the golden one
// clears the bundle's floor.
//
// EMBEDDING_BUNDLE names the bundle directory. Under xcodebuild, set
// TEST_RUNNER_EMBEDDING_BUNDLE instead; the runner strips the prefix, and the
// iOS simulator reads the host's file system, so the same path works there.
// EMBEDDING_PARITY_REPORT, when set, names a file to write the measurements to.

import Foundation
import Testing

import EmbeddingParity

struct Golden: Decodable {
    struct Case: Decodable {
        let id: String
        let kind: String
        let title: String?
        let text: String
        let prefixed: String
        let input_ids: [Int]
        let vector: [Float]
    }

    let name: String
    let model_sha256: String
    let min_cosine: Float
    let cases: [Case]
}

struct CaseResult: Encodable {
    let id: String
    let tokens: Int
    let prefix_ok: Bool
    let ids_ok: Bool
    let cosine: Float
    let ms: Double
    var ok: Bool
}

struct Report: Encodable {
    let runtime: String
    let platform: String
    let bundle: String
    let model_sha256: String
    let min_cosine: Float
    let load_ms: Int
    let resident_mb: [String: Int]
    let short_text_median_ms: Double
    let worst_cosine: Float
    let failures: [String]
    let cases: [CaseResult]
}

func residentMB() -> Int {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? Int(info.phys_footprint) / (1 << 20) : -1
}

func platformName() -> String {
    #if os(iOS)
        #if targetEnvironment(simulator)
            "iOS simulator \(ProcessInfo.processInfo.operatingSystemVersionString)"
        #else
            "iOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        #endif
    #else
        "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
    #endif
}

func elapsedMs(since start: ContinuousClock.Instant) -> Double {
    let d = ContinuousClock.now - start
    return Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15
}

@Test func goldenSet() async throws {
    let env = ProcessInfo.processInfo.environment
    let path = try #require(env["EMBEDDING_BUNDLE"], "set EMBEDDING_BUNDLE (or TEST_RUNNER_EMBEDDING_BUNDLE under xcodebuild) to the bundle directory")
    let bundle = URL(fileURLWithPath: path)
    let golden = try JSONDecoder().decode(Golden.self, from: Data(contentsOf: bundle.appendingPathComponent("golden.json")))

    let before = residentMB()
    let loadStart = ContinuousClock.now
    let embedder = try await Embedder(bundle: bundle)
    let loadMs = elapsedMs(since: loadStart)
    let loaded = residentMB()
    #expect(golden.model_sha256 == embedder.manifest.files["model.onnx"]?.sha256, "golden.json was made from a different model")

    var peak = loaded
    var results: [CaseResult] = []
    for c in golden.cases {
        let prefixed = c.kind == "query" ? embedder.queryText(c.text) : embedder.documentText(c.text, title: c.title)
        let ids = embedder.tokenize(c.prefixed)
        let start = ContinuousClock.now
        let vector = try embedder.embed(prefixed: c.prefixed)
        let ms = elapsedMs(since: start)
        peak = max(peak, residentMB())
        let cosine = zip(vector, c.vector).reduce(Float(0)) { $0 + $1.0 * $1.1 }
        var r = CaseResult(id: c.id, tokens: c.input_ids.count, prefix_ok: prefixed == c.prefixed, ids_ok: ids == c.input_ids, cosine: cosine, ms: (ms * 10).rounded() / 10, ok: false)
        r.ok = r.prefix_ok && r.ids_ok && r.cosine >= golden.min_cosine
        results.append(r)
        print(String(format: "%@  %.6f  %5d tok  %8.1f ms  %@%@%@", r.ok ? "ok  " : "FAIL", r.cosine, r.tokens, r.ms, c.id, r.prefix_ok ? "" : "  PREFIX", r.ids_ok ? "" : "  IDS"))
        #expect(r.prefix_ok, "\(c.id): prefixed text differs")
        #expect(r.ids_ok, "\(c.id): token IDs differ: \(ids) vs \(c.input_ids)")
        #expect(r.cosine >= golden.min_cosine, "\(c.id): cosine \(r.cosine)")
    }

    let short = results.filter { $0.tokens <= 64 }.map(\.ms).sorted()
    let report = Report(
        runtime: "Swift, onnxruntime-swift-package-manager 1.24.2, swift-transformers 1.3.5",
        platform: platformName(),
        bundle: golden.name,
        model_sha256: golden.model_sha256,
        min_cosine: golden.min_cosine,
        load_ms: Int(loadMs),
        resident_mb: ["before": before, "loaded": loaded, "peak": peak],
        short_text_median_ms: short.isEmpty ? 0 : short[short.count / 2],
        worst_cosine: results.map(\.cosine).min() ?? 0,
        failures: results.filter { !$0.ok }.map(\.id),
        cases: results
    )
    print("\(results.count - report.failures.count)/\(results.count) pass, worst cosine \(report.worst_cosine) (floor \(golden.min_cosine)), load \(report.load_ms) ms, short-text median \(report.short_text_median_ms) ms, footprint \(loaded) MB loaded / \(peak) MB peak")
    if let out = env["EMBEDDING_PARITY_REPORT"] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(report).write(to: URL(fileURLWithPath: out))
    }
}
