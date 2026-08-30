import Foundation
import CoreLocation
import WidgetKit

/// Wraps CLLocationManager, mirrors the latest fix into the App Group store, and
/// nudges WidgetKit to rebuild the timeline whenever the location changes.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined
    @Published private(set) var current: CLLocationCoordinate2D?
    @Published private(set) var lastUpdate: Date?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 2_000          // metres; a radar centre doesn't need precision

        authorization = manager.authorizationStatus
        if let stored = SharedLocationStore.load() {
            current = stored.coordinate
            lastUpdate = stored.timestamp
        }
        start()
    }

    var isAuthorized: Bool {
        // On macOS the only "granted" state is .authorizedAlways
        // (kCLAuthorizationStatusAuthorized shares its raw value).
        authorization == .authorizedAlways
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func refreshNow() {
        if isAuthorized { manager.requestLocation() }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorization = manager.authorizationStatus
            self.start()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.current = loc.coordinate
            self.lastUpdate = Date()
            SharedLocationStore.save(loc.coordinate)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep the last known fix; nothing actionable here.
    }
}
