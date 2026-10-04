#if os(macOS)
import CoreLocation
import Foundation

@MainActor
public protocol LocationSource: AnyObject {
    /// The `Date` is the fix's own timestamp (`CLLocation.timestamp`), never
    /// the moment it arrived — `startUpdatingLocation()` characteristically
    /// delivers a cached fix immediately, which can be minutes or hours old.
    var onLocation: ((LocationDetail, Date) -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
public final class SystemLocationSource: NSObject, LocationSource, CLLocationManagerDelegate {
    /// Metres of movement required before CoreLocation calls the delegate
    /// again.
    ///
    /// The trigger answers "which place is this — home, the office, the
    /// vet?", so the threshold has to clear two floors. Reported horizontal
    /// accuracy on this hardware is ~35m, so anything at or under that
    /// records jitter as travel. And the places being told apart are
    /// buildings, not rooms. 100m sits above the noise and below the
    /// distance separating any two places worth distinguishing.
    ///
    /// This was `kCLDistanceFilterNone` — every fix, unconditionally — which
    /// over four days on a stationary machine produced 1,187 rows describing
    /// one spot, spread across 8 coordinates that all fell inside a single
    /// accuracy radius. A location trigger that fires when nothing happened
    /// is not higher resolution; it is a clock with a coordinate attached.
    static let movementThresholdMetres: CLLocationDistance = 100

    public var onLocation: ((LocationDetail, Date) -> Void)?
    private let manager = CLLocationManager()

    public override init() {
        super.init()
        manager.delegate = self
        // Accuracy is requested to match the threshold rather than to beat
        // it: a place is identified at building scale, and asking for
        // `kCLAccuracyBest` buys resolution nothing reads while keeping the
        // higher-power location hardware engaged.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = Self.movementThresholdMetres
    }

    public func start() { manager.startUpdatingLocation() }
    public func stop() { manager.stopUpdatingLocation() }

    public nonisolated func locationManager(_ manager: CLLocationManager,
                                            didUpdateLocations locations: [CLLocation]) {
        // Delivered on the delegate's queue, which is the main queue here.
        MainActor.assumeIsolated {
            for location in locations {
                // A negative horizontalAccuracy means CoreLocation considers
                // the COORDINATE itself invalid, not just the accuracy
                // figure — latitude/longitude are documented as invalid too.
                // LocationDetail.latitude/.longitude are non-optional (fixed
                // schema), so there is no way to record "position unknown"
                // in a row: skip the fix rather than emit a garbage
                // coordinate. One invalid fix in a batch must not stop the
                // rest from being processed.
                guard location.horizontalAccuracy >= 0 else { continue }
                self.onLocation?(LocationDetail(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    horizontalAccuracy: location.horizontalAccuracy,
                    // CoreLocation signals "unavailable" with a negative
                    // accuracy; NULL is how the schema says unavailable.
                    altitude: location.verticalAccuracy >= 0 ? location.altitude : nil,
                    verticalAccuracy: location.verticalAccuracy >= 0 ? location.verticalAccuracy : nil,
                    speed: location.speed >= 0 ? location.speed : nil,
                    course: location.course >= 0 ? location.course : nil),
                    location.timestamp)
            }
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager,
                                            didFailWithError error: Error) {
        // A failed fix is not an event; the next successful one will arrive.
    }
}

/// Emits a `location` event for every fix CoreLocation delivers.
@MainActor
public final class LocationTrigger: ContextTrigger {
    public let kind: ContextEventKind = .location
    public let requiredPermission: ContextPermission = .location
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    private let source: any LocationSource
    private var isRunning = false

    public init(source: any LocationSource = SystemLocationSource()) {
        self.source = source
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        source.onLocation = { [weak self] detail, date in
            guard let self, self.isRunning else { return }
            self.onEvent?(.location(detail), date)
        }
        source.start()
    }

    public func stop() {
        isRunning = false
        source.onLocation = nil
        source.stop()
    }
}
#endif
