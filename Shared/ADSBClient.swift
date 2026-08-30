import Foundation

enum ADSBError: Error { case badURL, badResponse }

/// Minimal client for the adsb.lol (readsb‑style) point/radius endpoint.
enum ADSBClient {

    static func fetchNearby(latitude: Double,
                            longitude: Double,
                            radiusNM: Double) async throws -> [Aircraft] {

        let radius = min(250, max(1, Int(radiusNM.rounded())))
        let urlString = "\(RadarConfig.apiBase)/point/\(latitude)/\(longitude)/\(radius)"
        guard let url = URL(string: urlString) else { throw ADSBError.badURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("PlaneRadar/1.0 (+macOS widget; personal use)",
                         forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw ADSBError.badResponse
        }

        let decoded = try JSONDecoder().decode(ADSBResponse.self, from: data)
        let center = (lat: latitude, lon: longitude)

        var planes = decoded.aircraft.compactMap { $0.toAircraft() }
        for i in planes.indices {
            let p = (lat: planes[i].latitude, lon: planes[i].longitude)
            planes[i].distanceNM = Geo.distanceNM(from: center, to: p)
            planes[i].bearingDeg = Geo.bearingDegrees(from: center, to: p)
        }

        return planes
            .filter { $0.distanceNM <= radiusNM * 1.05 }
            .filter { RadarConfig.showGroundAircraft || !$0.onGround }
            .sorted { $0.distanceNM < $1.distanceNM }
    }
}
