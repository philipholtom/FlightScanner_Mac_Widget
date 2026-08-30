import Foundation

/// Central knobs for the radar. Edit these to taste.
enum RadarConfig {

    /// App Group identifier. Must match the "App Groups" capability on **both**
    /// the app and the widget target, and the value in both `.entitlements` files.
    static let appGroupID = "group.com.pholtom.PlaneRadar"

    /// Default radar coverage radius, in nautical miles. The menu‑bar app lets
    /// you change it live (persisted); this is the starting value.
    static let rangeNM: Double = 50

    /// Selectable ranges in the menu‑bar app's range picker (max 250 for the
    /// data source).
    static let rangeOptionsNM: [Double] = [10, 25, 50, 100, 150, 250]

    /// Include aircraft/vehicles that are on the ground. Off by default — near a
    /// big airport that's dozens of parked jets and airport vehicles.
    static let showGroundAircraft = false

    /// How often the widget asks WidgetKit to refresh, in seconds.
    /// WidgetKit treats this as a *hint* and enforces a per‑app daily budget, so
    /// in practice expect a real cadence closer to 15–30 minutes.
    static let refreshSeconds: TimeInterval = 5 * 60

    /// Used when Location Services are unavailable or permission hasn't been
    /// granted yet. Change these to your home coordinates.
    /// (Default: London Heathrow area.)
    static let fallbackLatitude: Double = 51.4700
    static let fallbackLongitude: Double = -0.4543

    /// A stored location older than this is treated as stale and the widget
    /// shows a "fallback location" hint.
    static let locationFreshness: TimeInterval = 60 * 60

    /// ADS‑B data source. `adsb.lol` is a free, key‑less, open aggregator
    /// (ODbL data); its `point/{lat}/{lon}/{radius}` query is what `ADSBClient`
    /// builds. Rate limit ~1 request/second, non‑commercial use.
    ///
    /// Alternatives (both decoded by `ADSBResponse`):
    ///   • https://api.adsb.fi/v2          — same path & shape as adsb.lol
    ///   • https://opendata.adsb.fi/api/v2 — uses .../lat/{lat}/lon/{lon}/dist/{nm}
    ///   • airplanes.live now requires you to email them for API access.
    static let apiBase = "https://api.adsb.lol/v2"
}
