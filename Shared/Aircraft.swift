import Foundation

/// A single aircraft, normalised for the radar.
struct Aircraft: Identifiable, Equatable {
    var id: String                 // ICAO 24‑bit hex address
    var callsign: String           // flight/callsign, trimmed (may be empty)
    var registration: String?
    var typeCode: String?          // e.g. "B738"
    var latitude: Double
    var longitude: Double
    var altitudeFeet: Int?         // barometric altitude; nil when on the ground
    var onGround: Bool
    var groundSpeedKt: Double?
    var trackDeg: Double?          // true track over ground

    // Filled in relative to the radar centre after fetching.
    var distanceNM: Double = 0
    var bearingDeg: Double = 0

    // Extra detail (shown when you click a flight).
    var typeDescription: String? = nil   // e.g. "BOEING 737-800"
    var squawk: String? = nil            // transponder code
    var verticalRateFpm: Int? = nil      // + climbing, − descending

    var displayName: String {
        if !callsign.isEmpty { return callsign }
        if let r = registration, !r.isEmpty { return r }
        return id.uppercased()
    }
}

// MARK: - Response decoding (adsb.lol / adsb.fi — the "readsb" JSON shape)

struct ADSBResponse: Decodable {
    let aircraft: [ADSBAircraft]

    private enum CodingKeys: String, CodingKey {
        case ac            // adsb.lol, airplanes.live
        case aircraft      // adsb.fi opendata
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        aircraft = (try? c.decode([ADSBAircraft].self, forKey: .ac))
            ?? (try? c.decode([ADSBAircraft].self, forKey: .aircraft))
            ?? []
    }
}

struct ADSBAircraft: Decodable {
    let hex: String?
    let flight: String?
    let r: String?
    let t: String?
    let lat: Double?
    let lon: Double?
    let alt_baro: AltBaro?
    let gs: Double?
    let track: Double?
    let desc: String?
    let squawk: String?
    let baro_rate: Double?
    let geom_rate: Double?

    /// `alt_baro` is a number in flight, or the string "ground" on the deck.
    enum AltBaro: Decodable {
        case feet(Int)
        case ground

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if (try? c.decode(String.self)) != nil {
                self = .ground            // "ground"
            } else if let i = try? c.decode(Int.self) {
                self = .feet(i)
            } else if let d = try? c.decode(Double.self) {
                self = .feet(Int(d))
            } else {
                self = .ground
            }
        }
    }

    func toAircraft() -> Aircraft? {
        guard let hex, let lat, let lon else { return nil }

        var altFeet: Int?
        var ground = false
        switch alt_baro {
        case .feet(let f): altFeet = f
        case .ground:      ground = true
        case .none:        break
        }

        let vrate = baro_rate ?? geom_rate

        return Aircraft(
            id: hex,
            callsign: (flight ?? "").trimmingCharacters(in: .whitespaces),
            registration: r,
            typeCode: t,
            latitude: lat,
            longitude: lon,
            altitudeFeet: altFeet,
            onGround: ground,
            groundSpeedKt: gs,
            trackDeg: track,
            typeDescription: desc,
            squawk: squawk,
            verticalRateFpm: vrate.map { Int($0) }
        )
    }
}
