import Foundation
import CoreLocation

struct StoredLocation: Codable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isFresh: Bool {
        Date().timeIntervalSince(timestamp) < RadarConfig.locationFreshness
    }
}

/// Shares the last known location from the menu‑bar app to the widget via the
/// App Group's shared `UserDefaults`.
enum SharedLocationStore {
    private static let key = "lastKnownLocation"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: RadarConfig.appGroupID)
    }

    static func save(_ coordinate: CLLocationCoordinate2D) {
        let value = StoredLocation(latitude: coordinate.latitude,
                                   longitude: coordinate.longitude,
                                   timestamp: Date())
        if let data = try? JSONEncoder().encode(value) {
            defaults?.set(data, forKey: key)
        }
    }

    static func load() -> StoredLocation? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StoredLocation.self, from: data)
    }

    /// Stored location, or the configured fallback with a `.distantPast` stamp.
    static func loadOrFallback() -> StoredLocation {
        load() ?? StoredLocation(latitude: RadarConfig.fallbackLatitude,
                                 longitude: RadarConfig.fallbackLongitude,
                                 timestamp: .distantPast)
    }
}
