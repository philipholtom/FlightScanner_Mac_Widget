import Foundation

/// Offline ICAO airline‑designator → name lookup. A callsign's leading letters
/// are its operator's ICAO code (e.g. `BAW117` → BAW → British Airways).
/// General‑aviation callsigns (registrations) simply won't match.
enum Airlines {

    static func name(forCallsign callsign: String) -> String? {
        let letters = callsign.prefix { $0.isLetter }
        guard letters.count >= 3 else { return nil }
        return byICAO[String(letters.prefix(3)).uppercased()]
    }

    static let byICAO: [String: String] = [
        // United Kingdom & Ireland
        "BAW": "British Airways", "SHT": "British Airways", "CFE": "BA CityFlyer",
        "EZY": "easyJet", "EJU": "easyJet Europe", "EXS": "Jet2",
        "TOM": "TUI Airways", "RYR": "Ryanair", "RUK": "Ryanair UK",
        "WUK": "Wizz Air UK", "VIR": "Virgin Atlantic", "LOG": "Loganair",
        "EZS": "easyJet Switzerland", "EFW": "Eastern Airways", "BCS": "European Air Transport",
        "NPT": "West Atlantic UK", "EIN": "Aer Lingus", "STK": "Aer Lingus Regional",
        "RRR": "Royal Air Force", "CWY": "Cathay Cargo",

        // Western & Central Europe
        "DLH": "Lufthansa", "CLH": "Lufthansa CityLine", "GEC": "Lufthansa Cargo",
        "EWG": "Eurowings", "EWE": "Eurowings", "AFR": "Air France",
        "KLM": "KLM", "KLC": "KLM Cityhopper", "TRA": "Transavia",
        "TVF": "Transavia France", "BEL": "Brussels Airlines", "SWR": "SWISS",
        "AUA": "Austrian Airlines", "DAT": "Brussels Airlines", "CFG": "Condor",
        "EDW": "Edelweiss Air", "SXD": "SunExpress Deutschland", "TUI": "TUI fly",
        "TFL": "TUI fly Netherlands", "TFY": "TUI fly Belgium", "PGT": "Pegasus Airlines",

        // Southern Europe
        "IBE": "Iberia", "IBS": "Iberia Express", "ANE": "Air Nostrum",
        "VLG": "Vueling", "AEA": "Air Europa", "TAP": "TAP Air Portugal",
        "AZA": "ITA Airways", "ITY": "ITA Airways", "MSC": "Air Cairo",
        "AEE": "Aegean Airlines", "OAL": "Olympic Air",
        "ROT": "Tarom", "CTN": "Croatia Airlines", "ADH": "Air Albania",

        // Nordics & Baltics
        "SAS": "SAS", "NAX": "Norwegian", "NOZ": "Norwegian",
        "IBK": "Norwegian", "FIN": "Finnair", "NRD": "Nordic Regional",
        "ICE": "Icelandair", "FXT": "Fly Play", "DTR": "Danish Air Transport",
        "BTI": "airBaltic", "LOT": "LOT Polish Airlines",

        // Eastern Europe & Turkey
        "WZZ": "Wizz Air", "THY": "Turkish Airlines", "SXS": "SunExpress",
        "AFL": "Aeroflot", "SDM": "Rossiya", "SBI": "S7 Airlines",
        "AUI": "Ukraine International", "UKL": "Ukraine Air Alliance",

        // Middle East
        "UAE": "Emirates", "ETD": "Etihad Airways", "QTR": "Qatar Airways",
        "GFA": "Gulf Air", "ABY": "Air Arabia", "SVA": "Saudia",
        "KAC": "Kuwait Airways", "ELY": "El Al", "RJA": "Royal Jordanian",
        "MEA": "Middle East Airlines", "MSR": "EgyptAir", "OMA": "Oman Air",
        "FDB": "flydubai", "RBG": "Air Arabia Egypt",

        // Africa
        "RAM": "Royal Air Maroc", "DAH": "Air Algérie", "TAR": "Tunisair",
        "ETH": "Ethiopian Airlines", "KQA": "Kenya Airways", "SAA": "South African Airways",
        "MAU": "Air Mauritius", "RWD": "RwandAir",

        // North America
        "AAL": "American Airlines", "DAL": "Delta Air Lines", "UAL": "United Airlines",
        "SWA": "Southwest Airlines", "JBU": "JetBlue", "ASA": "Alaska Airlines",
        "ACA": "Air Canada", "ROU": "Air Canada Rouge", "JZA": "Air Canada Express",
        "WJA": "WestJet", "TSC": "Air Transat", "POE": "Porter Airlines",
        "FFT": "Frontier Airlines", "NKS": "Spirit Airlines", "AAY": "Allegiant Air",
        "SCX": "Sun Country", "HAL": "Hawaiian Airlines", "AMX": "Aeroméxico",
        "VOI": "Volaris",

        // Asia‑Pacific
        "JAL": "Japan Airlines", "ANA": "All Nippon Airways", "CPA": "Cathay Pacific",
        "HDA": "Cathay Dragon", "SIA": "Singapore Airlines", "SLK": "Singapore Airlines",
        "QFA": "Qantas", "JST": "Jetstar", "ANZ": "Air New Zealand",
        "VOZ": "Virgin Australia", "CCA": "Air China", "CES": "China Eastern",
        "CSN": "China Southern", "CHH": "Hainan Airlines", "CAL": "China Airlines",
        "EVA": "EVA Air", "KAL": "Korean Air", "AAR": "Asiana Airlines",
        "AIC": "Air India", "IGO": "IndiGo", "SEJ": "SpiceJet",
        "THA": "Thai Airways", "MAS": "Malaysia Airlines", "GIA": "Garuda Indonesia",
        "PAL": "Philippine Airlines", "AXM": "AirAsia", "CEB": "Cebu Pacific",

        // Latin America
        "LAN": "LATAM", "TAM": "LATAM Brasil", "GLO": "GOL",
        "AZU": "Azul", "ARG": "Aerolíneas Argentinas", "AVA": "Avianca",
        "CMP": "Copa Airlines",

        // Cargo
        "FDX": "FedEx Express", "UPS": "UPS Airlines", "GTI": "Atlas Air",
        "CLX": "Cargolux", "CKS": "Kalitta Air", "BOX": "AeroLogic",
        "ABW": "AirBridgeCargo", "QAC": "Qatar Airways Cargo", "TAY": "ASL Airlines Belgium",
        "CLU": "Cargolux Italia", "SQC": "Singapore Airlines Cargo", "MPH": "Martinair",
    ]
}
