import SwiftUI

/// Shared colour / label rules so the menu bar list and the widget agree.
enum AircraftStyle {

    /// Colour by altitude band (feet), classic ATC‑ish ramp.
    static func color(for plane: Aircraft) -> Color {
        if plane.onGround { return Color(white: 0.55) }
        guard let alt = plane.altitudeFeet else { return .green }
        switch alt {
        case ..<3_000:        return Color(red: 1.00, green: 0.45, blue: 0.45)  // low / departing / arriving
        case 3_000..<10_000:  return Color(red: 1.00, green: 0.80, blue: 0.35)  // climb / descent
        case 10_000..<25_000: return Color(red: 0.55, green: 1.00, blue: 0.55)  // mid
        default:              return Color(red: 0.55, green: 0.85, blue: 1.00)  // cruise
        }
    }

    /// Short altitude label: "GND", "FL350", or "—".
    static func altLabel(for plane: Aircraft) -> String {
        if plane.onGround { return "GND" }
        guard let alt = plane.altitudeFeet else { return "—" }
        if alt >= 18_000 { return "FL\(alt / 100)" }
        return "\(alt) ft"
    }
}
