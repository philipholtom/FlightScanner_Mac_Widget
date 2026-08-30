import SwiftUI

/// Menu‑bar host app. Its jobs:
///  1. Own the CoreLocation permission and keep the shared location fresh.
///  2. Give you a quick popover with the current nearby traffic + a manual refresh.
///
/// It has no Dock icon (see `LSUIElement` in Info.plist).
@main
struct PlaneRadarApp: App {
    @StateObject private var location = LocationManager()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(location)
        } label: {
            Image(systemName: "dot.radiowaves.up.forward")
        }
        .menuBarExtraStyle(.window)
    }
}
