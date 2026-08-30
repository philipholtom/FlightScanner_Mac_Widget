import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - Timeline entry

struct RadarEntry: TimelineEntry {
    let date: Date
    let center: CLLocationCoordinate2D
    let locationIsFresh: Bool
    let aircraft: [Aircraft]
    let failed: Bool
}

// MARK: - Provider

struct RadarProvider: TimelineProvider {

    func placeholder(in context: Context) -> RadarEntry {
        RadarEntry(date: Date(),
                   center: CLLocationCoordinate2D(latitude: RadarConfig.fallbackLatitude,
                                                  longitude: RadarConfig.fallbackLongitude),
                   locationIsFresh: false,
                   aircraft: RadarProvider.demoAircraft,
                   failed: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (RadarEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task { completion(await makeEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RadarEntry>) -> Void) {
        Task {
            let entry = await makeEntry()
            let next = Date().addingTimeInterval(RadarConfig.refreshSeconds)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func makeEntry() async -> RadarEntry {
        let stored = SharedLocationStore.load()
        let center = stored?.coordinate
            ?? CLLocationCoordinate2D(latitude: RadarConfig.fallbackLatitude,
                                      longitude: RadarConfig.fallbackLongitude)
        let fresh = stored?.isFresh ?? false

        do {
            let planes = try await ADSBClient.fetchNearby(
                latitude: center.latitude,
                longitude: center.longitude,
                radiusNM: RadarConfig.rangeNM)
            return RadarEntry(date: Date(), center: center,
                              locationIsFresh: fresh, aircraft: planes, failed: false)
        } catch {
            return RadarEntry(date: Date(), center: center,
                              locationIsFresh: fresh, aircraft: [], failed: true)
        }
    }

    /// Only used for the gallery placeholder / preview.
    static let demoAircraft: [Aircraft] = [
        make("BAW117", 12, 38, 36_000, 41),
        make("EZY43QK", 21, 145, 12_500, 160),
        make("RYR8442", 30, 250, 24_000, 268),
        make("N512SR", 8, 305, 4_200, 300),
        make("DLH4EP", 44, 95, 38_000, 88),
    ]

    private static func make(_ cs: String, _ dist: Double, _ brg: Double,
                             _ alt: Int, _ track: Double) -> Aircraft {
        Aircraft(id: cs, callsign: cs, registration: nil, typeCode: nil,
                 latitude: 0, longitude: 0, altitudeFeet: alt, onGround: false,
                 groundSpeedKt: 420, trackDeg: track,
                 distanceNM: dist, bearingDeg: brg)
    }
}

// MARK: - Widget

struct PlaneRadarWidget: Widget {
    let kind = "PlaneRadarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RadarProvider()) { entry in
            RadarWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    RadialGradient(colors: [Color(white: 0.10), .black],
                                   center: .center, startRadius: 2, endRadius: 260)
                }
        }
        .configurationDisplayName("Plane Radar")
        .description("Aircraft within \(Int(RadarConfig.rangeNM)) nm of your location.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
