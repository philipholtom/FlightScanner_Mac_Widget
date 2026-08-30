import SwiftUI
import AppKit

/// The panel shown from the menu‑bar icon: the radar dial, a range picker, and
/// the nearest traffic — click any flight (row or blip) for its details.
struct MenuContentView: View {
    @EnvironmentObject var location: LocationManager

    @AppStorage("radarRangeNM") private var rangeNM: Double = RadarConfig.rangeNM

    @State private var planes: [Aircraft] = []
    @State private var loading = false
    @State private var errorText: String?
    @State private var loadedAt: Date?
    @State private var selected: Aircraft?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Divider()
            locationSection
            radar
            Divider()
            if let selected {
                FlightDetailView(aircraft: current(selected)) { self.selected = nil }
            } else {
                trafficSection
            }
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
        .task { await refresh() }
        .onChange(of: rangeNM) { _, _ in
            selected = nil
            Task { await refresh() }
        }
    }

    private var scene: RadarScene {
        RadarScene(aircraft: planes,
                   rangeNM: rangeNM,
                   date: loadedAt ?? .now,
                   locationIsFresh: location.current != nil,
                   failed: errorText != nil)
    }

    private var radar: some View {
        RadarDial(scene: scene,
                  highlightID: selected?.id,
                  onSelect: { selected = $0 })
            .frame(width: 250, height: 250)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RadialGradient(colors: [Color(white: 0.11), .black],
                               center: .center, startRadius: 2, endRadius: 175),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            Image(systemName: "dot.radiowaves.up.forward")
            Text("Plane Radar").font(.headline)
            Spacer()
            Picker("Range", selection: $rangeNM) {
                ForEach(RadarConfig.rangeOptionsNM, id: \.self) { r in
                    Text("\(Int(r)) nm").tag(r)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
        }
    }

    @ViewBuilder private var locationSection: some View {
        if let c = location.current {
            Text(String(format: "Centre  %.3f, %.3f", c.latitude, c.longitude))
                .font(.callout.monospaced())
            if let u = location.lastUpdate {
                Text("Fix updated \(u.formatted(date: .omitted, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } else {
            Text("No location yet — using fallback \(String(format: "%.3f, %.3f", RadarConfig.fallbackLatitude, RadarConfig.fallbackLongitude))")
                .font(.callout).foregroundStyle(.secondary)
        }

        if !location.isAuthorized {
            Button("Enable Location Access…") { location.start() }
                .buttonStyle(.link)
        }
    }

    @ViewBuilder private var trafficSection: some View {
        if loading && planes.isEmpty {
            HStack { ProgressView().controlSize(.small); Text("Contacting adsb.lol…") }
                .font(.callout)
        } else if let errorText {
            Label(errorText, systemImage: "exclamationmark.triangle")
                .font(.callout).foregroundStyle(.secondary)
        } else if planes.isEmpty {
            Text("No aircraft in range right now.")
                .font(.callout).foregroundStyle(.secondary)
        } else {
            ForEach(planes.prefix(7)) { p in
                Button { selected = p } label: {
                    HStack(spacing: 8) {
                        Circle().fill(AircraftStyle.color(for: p)).frame(width: 7, height: 7)
                        Text(p.displayName)
                            .font(.callout.monospaced())
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(AircraftStyle.altLabel(for: p))
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                        Text(String(format: "%.0f nm", p.distanceNM))
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(width: 46, alignment: .trailing)
                        Image(systemName: "chevron.right")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if let loadedAt {
                Text("\(planes.count) contacts • \(loadedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                location.refreshNow()
                Task { await refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }

    // MARK: Data

    /// Latest data for a selected aircraft (so the detail view stays live across
    /// refreshes); falls back to the snapshot we selected.
    private func current(_ a: Aircraft) -> Aircraft {
        planes.first { $0.id == a.id } ?? a
    }

    private func refresh() async {
        loading = true
        errorText = nil
        defer { loading = false }

        let coord = location.current ?? SharedLocationStore.loadOrFallback().coordinate
        do {
            planes = try await ADSBClient.fetchNearby(
                latitude: coord.latitude,
                longitude: coord.longitude,
                radiusNM: rangeNM)
            loadedAt = Date()
        } catch {
            errorText = "Couldn’t reach the ADS‑B service."
        }
    }
}
