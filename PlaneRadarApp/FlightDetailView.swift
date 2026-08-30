import SwiftUI
import AppKit

/// Shown in the dropdown when you click a flight (row or blip).
struct FlightDetailView: View {
    let aircraft: Aircraft
    var onBack: () -> Void

    @State private var route: FlightRoute?
    @State private var routeState: RouteState = .loading
    private enum RouteState { case loading, done }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onBack) {
                Label("All traffic", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .font(.callout)
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Circle().fill(AircraftStyle.color(for: aircraft)).frame(width: 9, height: 9)
                Text(aircraft.displayName)
                    .font(.title3.monospaced().weight(.semibold))
                if aircraft.onGround {
                    Text("ON GROUND")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(.secondary.opacity(0.2), in: Capsule())
                }
            }

            if let airline {
                Text(airline).font(.callout.weight(.medium))
            }
            if !subtitle.isEmpty {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            routeStrip

            Divider()

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 5) {
                gridRow("Altitude", altitudeText)
                if let v = verticalText { gridRow("Vertical", v) }
                gridRow("Ground speed", aircraft.groundSpeedKt.map { "\(Int($0)) kt" } ?? "—")
                gridRow("Track", aircraft.trackDeg.map { "\(Int($0))°  \(Geo.compass($0))" } ?? "—")
                gridRow("Bearing", String(format: "%.1f nm  •  %03.0f° %@",
                                          aircraft.distanceNM, aircraft.bearingDeg,
                                          Geo.compass(aircraft.bearingDeg)))
                gridRow("Squawk", aircraft.squawk ?? "—")
                gridRow("Position", String(format: "%.4f, %.4f", aircraft.latitude, aircraft.longitude))
                gridRow("ICAO", aircraft.id.uppercased())
            }
            .font(.callout)

            if let url = trackURL {
                Link(destination: url) {
                    Label("Open on adsb.lol map", systemImage: "map")
                }
                .font(.callout)
                .padding(.top, 2)
            }
        }
        .task(id: aircraft.id) {
            routeState = .loading
            route = await RouteClient.route(callsign: aircraft.callsign)
            routeState = .done
        }
    }

    // MARK: route

    @ViewBuilder private var routeStrip: some View {
        if let o = route?.origin, let d = route?.destination {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 8) {
                    Text(o.code).font(.callout.monospaced().weight(.bold))
                    Image(systemName: "arrow.right").font(.caption).foregroundStyle(.secondary)
                    Text(d.code).font(.callout.monospaced().weight(.bold))
                }
                Text("\(o.place)  →  \(d.place)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.top, 1)
        } else if routeState == .loading {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Looking up route…").font(.caption).foregroundStyle(.secondary)
            }
        } else {
            Text("Route not in database").font(.caption).foregroundStyle(.tertiary)
        }
    }

    // MARK: bits

    /// Airline from the route database if we have it, else the offline
    /// callsign‑prefix table.
    private var airline: String? {
        route?.airlineName ?? Airlines.name(forCallsign: aircraft.callsign)
    }

    private var subtitle: String {
        [aircraft.registration, aircraft.typeCode, aircraft.typeDescription]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "  •  ")
    }

    private var altitudeText: String {
        if aircraft.onGround { return "on ground" }
        guard let ft = aircraft.altitudeFeet else { return "—" }
        let fl = ft >= 18_000 ? "  (FL\(ft / 100))" : ""
        return "\(ft.formatted()) ft\(fl)"
    }

    private var verticalText: String? {
        guard let fpm = aircraft.verticalRateFpm, abs(fpm) >= 100 else {
            return aircraft.onGround ? nil : "level"
        }
        let arrow = fpm > 0 ? "▲ climbing" : "▼ descending"
        return "\(arrow)  \(abs(fpm).formatted()) fpm"
    }

    private var trackURL: URL? {
        guard !aircraft.id.isEmpty else { return nil }
        return URL(string: "https://adsb.lol/?icao=\(aircraft.id)")
    }

    private func gridRow(_ key: String, _ value: String) -> some View {
        GridRow {
            Text(key).foregroundStyle(.secondary)
            Text(value).monospaced().textSelection(.enabled)
        }
    }
}
