import Foundation

/// One end of a flight's route.
struct AirportRef: Equatable {
    var iata: String
    var icao: String
    var municipality: String
    var name: String
    var countryName: String

    /// Short code for headline display (IATA if known, else ICAO).
    var code: String { iata.isEmpty ? icao : iata }

    /// e.g. "London" — falls back to the airport name.
    var place: String { municipality.isEmpty ? name : municipality }
}

struct FlightRoute: Equatable {
    var airlineName: String?
    var origin: AirportRef?
    var destination: AirportRef?
}

/// Callsign → route lookup via adsbdb.com (free, key‑less). Route/airline data is
/// NOT in the ADS‑B broadcast — this is a separate crowd‑maintained database.
enum RouteClient {

    static func route(callsign: String) async -> FlightRoute? {
        let cs = callsign.trimmingCharacters(in: .whitespaces).uppercased()
        guard cs.count >= 3,
              let url = URL(string: "https://api.adsbdb.com/v0/callsign/\(cs)")
        else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("PlaneRadar/1.0 (personal use)", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(ADSBDBResponse.self, from: data),
              let fr = decoded.response.flightroute
        else { return nil }

        return FlightRoute(airlineName: fr.airline?.name?.nilIfBlank,
                           origin: fr.origin?.ref,
                           destination: fr.destination?.ref)
    }
}

// MARK: - adsbdb.com decoding
// `response` is an object on a hit and the string "unknown callsign" on a miss —
// so the whole decode just fails on a miss and we return nil.

private struct ADSBDBResponse: Decodable {
    let response: Wrapper
    struct Wrapper: Decodable { let flightroute: Route? }

    struct Route: Decodable {
        let airline: Airline?
        let origin: Port?
        let destination: Port?
    }
    struct Airline: Decodable { let name: String? }
    struct Port: Decodable {
        let iata_code: String?
        let icao_code: String?
        let municipality: String?
        let name: String?
        let country_name: String?

        var ref: AirportRef {
            AirportRef(iata: iata_code ?? "", icao: icao_code ?? "",
                       municipality: municipality ?? "", name: name ?? "",
                       countryName: country_name ?? "")
        }
    }
}

private extension String {
    var nilIfBlank: String? { isEmpty ? nil : self }
}
