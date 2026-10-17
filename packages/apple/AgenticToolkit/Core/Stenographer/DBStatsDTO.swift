import Foundation

/// Per-lane bounded-execution counters, for a daemon's database-stats endpoint.
public struct DBStatsDTO: Codable, Sendable {
    public struct Pool: Codable, Sendable {
        public let pool: String
        public let inFlight: Int
        public let completed: Int
        public let evicted: Int
        public let p50Ms: Double
        public let p99Ms: Double

        public init(
            pool: String, inFlight: Int, completed: Int, evicted: Int, p50Ms: Double, p99Ms: Double
        ) {
            self.pool = pool
            self.inFlight = inFlight
            self.completed = completed
            self.evicted = evicted
            self.p50Ms = p50Ms
            self.p99Ms = p99Ms
        }
    }
    public let write: [Pool]
    public let read: [Pool]

    public init(write: [Pool], read: [Pool]) {
        self.write = write
        self.read = read
    }
}
