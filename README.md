# FlightScanner — a menu‑bar plane radar for macOS

A menu‑bar app that finds your location and shows a radar scope of nearby
aircraft — click the top‑bar icon and the dial drops down, with the nearest
flights listed underneath. Pick a **range** from 10 to 250 nm (remembered), and
**click any flight** — a row or a blip on the scope — for altitude, vertical
rate, speed, heading, squawk, position and a link to the live map.

```
        N
    ·   ▲            ▲  = aircraft, pointing along its ground track
  ·    · ▲           colour = altitude band
W ─────•───── E      •  = you
  ·  ▲    ·          rings at 12.5 / 25 / 37.5 / 50 nm
     ·  ·
        S     23 aircraft • 14:07
```

## The short version

```bash
./bootstrap.sh          # installs XcodeGen if needed, generates + opens the project
```

In Xcode: pick the **PlaneRadar** scheme → **Run** (▶). No Apple Developer
account, no signing setup — it builds "Sign to Run Locally". The radiowaves icon
appears near your clock; click it, allow the one‑time location prompt, and the
radar fills in.

Want it always there → **System Settings › General › Login Items › Open at Login**
→ add `PlaneRadar.app`.

## Requirements

- **macOS 14+**
- **Xcode 15+** — a full Xcode (not just Command Line Tools). SwiftUI's `Canvas`
  and the build both need it. `xcode-select -p` should end in `Xcode.app/...`;
  if not: `sudo xcode-select -s /Applications/Xcode.app` (or `Xcode-beta.app`).
- **XcodeGen** (`brew install xcodegen`) — generates the `.xcodeproj` from
  `project.yml`. `bootstrap.sh` installs it for you. Manual setup below if you'd
  rather not.

## What's in the project

| Scheme | Needs a Team? | What it is |
| --- | --- | --- |
| **PlaneRadar** | No | The menu‑bar app. This is the one you want. |
| **PlaneRadarPreview** | No | A plain window showing the Small/Medium/Large layouts side‑by‑side against live data — handy for tweaking the look. |
| **PlaneRadarWidget** | **Yes** | The Notification Center / desktop widget. Built but parked — see below. |

### Why the widget is parked

A WidgetKit widget runs as a separate sandboxed process. Getting your location
into that sandbox needs an **App Group** entitlement, which Apple only enables on
a **paid** Apple Developer membership. The menu‑bar app has no such constraint —
it holds the location itself.

The widget code is all here (`PlaneRadarWidget/`) and compiles. To ship it:
switch the `PlaneRadarWidget` target to `CODE_SIGN_STYLE: Automatic` with your
Team, set `CODE_SIGNING_ALLOWED: YES`, re‑add the `embed` dependency under the
`PlaneRadar` target in `project.yml`, and run `./bootstrap.sh`.

## Location

`LocationManager` requests "when in use" access (one system prompt) and keeps the
fix in memory. If you deny it, or before you've answered, the radar centres on
`RadarConfig.fallbackLatitude/Longitude` and the dial shows a "fallback" tag —
edit those to your home coordinates.

## Refresh

The menu‑bar dropdown refetches every time you open it, plus there's a **Refresh**
button. The sweep line advances once a minute as a "this is live" cue.

## Data source

[adsb.lol](https://adsb.lol) — a free, key‑less, community ADS‑B aggregator
(ODbL data). `ADSBClient` calls its `point/{lat}/{lon}/{radius}` endpoint;
~1 request/second, non‑commercial use.

`ADSBResponse` decodes the common "readsb" JSON shape (`ac`/`aircraft` array), so
most readsb‑style feeds work by changing `RadarConfig.apiBase` — check the path
matches `/point/{lat}/{lon}/{radius}`. Some fields (e.g. `desc`, the long type
name) aren't in every feed and the flight detail just omits them.

Aircraft not transmitting ADS‑B (most military, some GA) won't appear. Ground
traffic is hidden by default (`RadarConfig.showGroundAircraft`).

**Airline & route aren't in ADS‑B** — the aircraft only broadcasts hex, callsign,
position, altitude, speed, squawk. So the flight detail derives them separately:
`Shared/Airlines.swift` is an offline ICAO‑prefix → airline table (instant,
~85% of airliners), and `Shared/RouteClient.swift` calls
[adsbdb.com](https://www.adsbdb.com) (`/v0/callsign/{callsign}`, free, key‑less)
for the airline plus origin/destination airports. Both fail soft — GA and
uncommon callsigns just show "Route not in database".

## Customising — all in `Shared/RadarConfig.swift`

| Knob | Meaning |
| --- | --- |
| `rangeNM` | Radar radius (also the API query radius), max 250. |
| `showGroundAircraft` | Include parked / taxiing aircraft. Default off. |
| `fallbackLatitude/Longitude` | Centre when no location is available. |
| `apiBase` | ADS‑B endpoint. |

Marker colours / altitude bands: `Shared/AircraftStyle.swift`.
Rings, sweep, triangle size, labels: `Shared/RadarView.swift`.

**App icon:** `PlaneRadarApp/Assets.xcassets/AppIcon.appiconset`. Regenerate the
PNGs after editing the artwork in `Tools/make_icon.swift`:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun swiftc -parse-as-library -O -o /tmp/icongen Tools/make_icon.swift
/tmp/icongen PlaneRadarApp/Assets.xcassets/AppIcon.appiconset
```

## Manual project setup (no XcodeGen)

1. New Xcode project → **macOS App** → name `PlaneRadar`, SwiftUI lifecycle.
2. Delete the generated `ContentView` / `App` file; add everything under
   `PlaneRadarApp/` and `Shared/`.
3. Signing & Capabilities → set signing to **Sign to Run Locally** (or add your
   Team). The `NSLocation*UsageDescription` keys are already in
   `PlaneRadarApp/Info.plist`.
4. Deployment target macOS 14.0. Build & run.

(The `PlaneRadarWidget/` and `Preview/` folders are optional extras.)

## Project layout

```
Shared/                    used by every target
  RadarConfig.swift          all the knobs
  Geo.swift                  haversine, bearing, polar→screen projection
  Aircraft.swift             model + readsb-style JSON decoding (adsb.lol / adsb.fi)
  ADSBClient.swift           async fetch for the point/radius endpoint
  AircraftStyle.swift        colour / label rules
  RadarView.swift            RadarScene + RadarDial (the scope) + FlightList
  SharedLocationStore.swift  App Group bridge — only used by the parked widget
PlaneRadarApp/               the menu-bar app
  PlaneRadarApp.swift          @main MenuBarExtra
  LocationManager.swift        CoreLocation
  MenuContentView.swift        the dropdown: radar dial + nearest flights
  FlightDetailView.swift       per-flight detail + adsbdb route lookup
  Assets.xcassets/AppIcon      the app icon
  Info.plist  PlaneRadar.entitlements
PlaneRadarWidget/            parked — the Notification Center widget
  PlaneRadarWidgetBundle.swift  @main
  PlaneRadarWidget.swift        TimelineProvider + StaticConfiguration
  RadarWidgetView.swift         maps RadarEntry → the shared RadarDial
  Info.plist  PlaneRadarWidget.entitlements
Preview/PreviewApp.swift     the side-by-side preview window
Tools/make_icon.swift        renders the AppIcon PNGs
project.yml   bootstrap.sh
```

## Licence

GPL‑3.0 (see `LICENSE`).
