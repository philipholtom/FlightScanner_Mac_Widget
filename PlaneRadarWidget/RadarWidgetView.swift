import SwiftUI
import WidgetKit

/// Maps the widget's `RadarEntry` onto the shared `RadarScene` / `RadarDial`
/// (which live in `Shared/RadarView.swift` and know nothing about WidgetKit).
struct RadarWidgetView: View {
    var entry: RadarEntry
    @Environment(\.widgetFamily) private var family

    private var scene: RadarScene {
        RadarScene(aircraft: entry.aircraft,
                   rangeNM: RadarConfig.rangeNM,
                   date: entry.date,
                   locationIsFresh: entry.locationIsFresh,
                   failed: entry.failed)
    }

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 12) {
                RadarDial(scene: scene)
                FlightList(scene: scene, limit: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .systemLarge:
            VStack(spacing: 10) {
                RadarDial(scene: scene)
                FlightList(scene: scene, limit: 7)
            }
        default:
            RadarDial(scene: scene)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    PlaneRadarWidget()
} timeline: {
    RadarEntry(date: .now,
               center: .init(latitude: RadarConfig.fallbackLatitude,
                             longitude: RadarConfig.fallbackLongitude),
               locationIsFresh: true,
               aircraft: RadarProvider.demoAircraft,
               failed: false)
}
