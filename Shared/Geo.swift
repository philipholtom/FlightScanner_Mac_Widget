import Foundation
import CoreGraphics

/// Great‑circle helpers plus a polar → screen projection for the radar.
enum Geo {

    /// Mean Earth radius in nautical miles.
    static let earthRadiusNM = 3440.065

    /// Haversine distance between two lat/lon points, in nautical miles.
    static func distanceNM(from a: (lat: Double, lon: Double),
                           to b: (lat: Double, lon: Double)) -> Double {
        let dLat = (b.lat - a.lat) * .pi / 180
        let dLon = (b.lon - a.lon) * .pi / 180
        let lat1 = a.lat * .pi / 180
        let lat2 = b.lat * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
              + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadiusNM * asin(min(1, sqrt(h)))
    }

    /// Initial bearing from `a` to `b`, in degrees clockwise from true north (0..<360).
    static func bearingDegrees(from a: (lat: Double, lon: Double),
                               to b: (lat: Double, lon: Double)) -> Double {
        let lat1 = a.lat * .pi / 180
        let lat2 = b.lat * .pi / 180
        let dLon = (b.lon - a.lon) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    /// 16‑point compass abbreviation for a bearing in degrees.
    static func compass(_ degrees: Double) -> String {
        let points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let i = Int((degrees.truncatingRemainder(dividingBy: 360) / 22.5).rounded())
        return points[(i % 16 + 16) % 16]
    }

    /// Convert a (distance, bearing) pair to a screen point.
    /// North is up; bearing increases clockwise. Distance is clamped to `rangeNM`.
    static func point(center: CGPoint,
                      pixelRadius: Double,
                      rangeNM: Double,
                      distanceNM: Double,
                      bearingDeg: Double) -> CGPoint {
        let clamped = min(max(distanceNM, 0), rangeNM)
        let r = (clamped / rangeNM) * pixelRadius
        let theta = bearingDeg * .pi / 180
        return CGPoint(x: center.x + r * sin(theta),
                       y: center.y - r * cos(theta))
    }
}
