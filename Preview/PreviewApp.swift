import SwiftUI
import AppKit
import CoreLocation

/// A plain window that renders the widget layouts against **live** ADS‑B data,
/// so you can see the radar without signing / installing the widget.
///
///   • Run the `PlaneRadarPreview` scheme, or
///   • set `RADAR_SNAPSHOT=/path/to/out.png` in the environment and it renders
///     the three sizes to a PNG and quits.
@main
struct PlaneRadarPreviewApp: App {
    var body: some Scene {
        WindowGroup("Plane Radar — Preview") {
            PreviewRootView()
        }
        .defaultSize(width: 780, height: 460)
    }
}

struct PreviewRootView: View {
    @State private var entry = RadarEntry(
        date: .now,
        center: CLLocationCoordinate2D(latitude: RadarConfig.fallbackLatitude,
                                       longitude: RadarConfig.fallbackLongitude),
        locationIsFresh: true, aircraft: [], failed: false)
    @State private var loading = true
    @State private var errorText: String?

    private let cardBG = RadialGradient(colors: [Color(white: 0.11), .black],
                                        center: .center, startRadius: 2, endRadius: 280)

    private var scene: RadarScene {
        RadarScene(aircraft: entry.aircraft, date: entry.date,
                   locationIsFresh: entry.locationIsFresh, failed: entry.failed)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Text("Live ADS‑B • \(Int(RadarConfig.rangeNM)) nm • \(entry.aircraft.count) aircraft")
                    .font(.headline)
                if loading { ProgressView().controlSize(.small) }
                Spacer()
                Button { Task { await load() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            }
            if let errorText {
                Label(errorText, systemImage: "exclamationmark.triangle")
                    .font(.callout).foregroundStyle(.orange)
            }
            sizes
        }
        .padding(20)
        .frame(minWidth: 760, minHeight: 440)
        .task {
            await load()
            if let path = ProcessInfo.processInfo.environment["RADAR_SNAPSHOT"] {
                snapshot(to: path)
            }
        }
    }

    private var sizes: some View {
        HStack(alignment: .top, spacing: 22) {
            card(158, 158, "Small")  { RadarDial(scene: scene) }
            card(338, 158, "Medium") {
                HStack(spacing: 12) {
                    RadarDial(scene: scene)
                    FlightList(scene: scene, limit: 5).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            card(338, 354, "Large") {
                VStack(spacing: 10) {
                    RadarDial(scene: scene)
                    FlightList(scene: scene, limit: 7)
                }
            }
        }
    }

    @ViewBuilder
    private func card<C: View>(_ w: CGFloat, _ h: CGFloat, _ label: String,
                               @ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 6) {
            content()
                .padding(12)
                .frame(width: w, height: h)
                .background(cardBG)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Data

    private func load() async {
        loading = true; errorText = nil
        defer { loading = false }
        do {
            let planes = try await ADSBClient.fetchNearby(
                latitude: entry.center.latitude,
                longitude: entry.center.longitude,
                radiusNM: RadarConfig.rangeNM)
            entry = RadarEntry(date: .now, center: entry.center,
                               locationIsFresh: true, aircraft: planes, failed: false)
        } catch {
            errorText = "Couldn’t reach adsb.lol (\(error))."
            entry = RadarEntry(date: .now, center: entry.center,
                               locationIsFresh: true, aircraft: [], failed: true)
        }
    }

    @MainActor
    private func snapshot(to path: String) {
        let renderer = ImageRenderer(content:
            sizes.padding(24).background(Color(white: 0.06))
        )
        renderer.scale = 2
        if let img = renderer.nsImage,
           let tiff = img.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: path))
        }
        NSApp.terminate(nil)
    }
}
