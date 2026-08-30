import SwiftUI

/// Everything the radar drawing needs, with no dependency on WidgetKit — so the
/// menu‑bar app, the widget, and the preview window all render from the same code.
struct RadarScene {
    var aircraft: [Aircraft]
    var rangeNM: Double = RadarConfig.rangeNM
    var date: Date = .now
    var locationIsFresh: Bool = true
    var failed: Bool = false
}

// MARK: - The radar dial

struct RadarDial: View {
    var scene: RadarScene
    /// ICAO hex of a contact to ring on the scope (the one you've selected).
    var highlightID: String? = nil
    /// Called with the nearest contact when you click a blip. Nil = not tappable
    /// (the widget passes nil).
    var onSelect: ((Aircraft) -> Void)? = nil

    private var ringColor: Color { Color(red: 0.30, green: 0.95, blue: 0.55) }

    var body: some View {
        Canvas { context, size in
            draw(&context, size: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(alignment: .top)      { compass("N") }
        .overlay(alignment: .bottom)   { statusText }
        .overlay(alignment: .leading)  { compass("W") }
        .overlay(alignment: .trailing) { compass("E") }
        .overlay { tapCatcher }
    }

    @ViewBuilder private var tapCatcher: some View {
        if let onSelect {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { value in
                        if let hit = plane(at: value.location,
                                           in: CGSize(width: geo.size.width, height: geo.size.height)) {
                            onSelect(hit)
                        }
                    })
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// Nearest blip to a tap point, or nil if the tap missed everything.
    private func plane(at p: CGPoint, in size: CGSize) -> Aircraft? {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 4
        let range = max(scene.rangeNM, 1)
        var best: (Aircraft, CGFloat)?
        for a in scene.aircraft {
            let pt = Geo.point(center: center, pixelRadius: radius, rangeNM: range,
                               distanceNM: a.distanceNM, bearingDeg: a.bearingDeg)
            let d = hypot(pt.x - p.x, pt.y - p.y)
            if d < 18, best == nil || d < best!.1 { best = (a, d) }
        }
        return best?.0
    }

    private func compass(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(ringColor.opacity(0.65))
            .padding(2)
    }

    private var statusText: some View {
        Text(statusString)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(scene.failed ? .orange : ringColor.opacity(0.95))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.black.opacity(0.55), in: Capsule())
            .padding(.bottom, 4)
    }

    private var statusString: String {
        if scene.failed { return "signal lost" }
        let time = scene.date.formatted(date: .omitted, time: .shortened)
        let base = "\(scene.aircraft.count) ac • \(Int(scene.rangeNM))nm • \(time)"
        return scene.locationIsFresh ? base : base + " • fallback"
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 4
        guard radius > 0 else { return }
        let range = max(scene.rangeNM, 1)

        // Range rings
        for frac in [0.25, 0.5, 0.75, 1.0] {
            let r = radius * frac
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            ctx.stroke(Path(ellipseIn: rect),
                       with: .color(ringColor.opacity(frac == 1.0 ? 0.55 : 0.22)),
                       lineWidth: frac == 1.0 ? 1.3 : 0.8)
        }

        // Cross hairs
        var cross = Path()
        cross.move(to: CGPoint(x: center.x - radius, y: center.y))
        cross.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        cross.move(to: CGPoint(x: center.x, y: center.y - radius))
        cross.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        ctx.stroke(cross, with: .color(ringColor.opacity(0.16)), lineWidth: 0.6)

        // Clip the moving parts to the outer ring.
        ctx.clip(to: Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                            width: radius * 2, height: radius * 2)))

        // Sweep wedge — advances once per minute so it visibly moves between refreshes.
        let phase = scene.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 60) / 60
        let sweep = Angle.radians(phase * 2 * .pi - .pi / 2)
        var wedge = Path()
        wedge.move(to: center)
        wedge.addArc(center: center, radius: radius,
                     startAngle: sweep - .radians(0.6), endAngle: sweep, clockwise: false)
        wedge.closeSubpath()
        ctx.fill(wedge, with: .radialGradient(
            Gradient(colors: [ringColor.opacity(0.30), ringColor.opacity(0.0)]),
            center: center, startRadius: 0, endRadius: radius))

        // Aircraft
        for plane in scene.aircraft {
            let pt = Geo.point(center: center, pixelRadius: radius, rangeNM: range,
                               distanceNM: plane.distanceNM, bearingDeg: plane.bearingDeg)
            ctx.fill(triangle(at: pt, headingDeg: plane.trackDeg ?? plane.bearingDeg, size: 4.5),
                     with: .color(AircraftStyle.color(for: plane)))
        }

        // Label a few airborne contacts when the dial is big enough that the text
        // clears the centre cluster.
        if radius > 110 {
            var placed: [CGPoint] = []
            let candidates = scene.aircraft.filter { !$0.onGround && $0.distanceNM > 6 }
            for plane in candidates where placed.count < 3 {
                let pt = Geo.point(center: center, pixelRadius: radius, rangeNM: range,
                                   distanceNM: plane.distanceNM, bearingDeg: plane.bearingDeg)
                if placed.contains(where: { hypot($0.x - pt.x, $0.y - pt.y) < 30 }) { continue }
                placed.append(pt)
                let label = Text(plane.displayName)
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                ctx.draw(label, at: CGPoint(x: pt.x, y: pt.y - 9), anchor: .center)
            }
        }

        // Ring the selected contact
        if let highlightID, let sel = scene.aircraft.first(where: { $0.id == highlightID }) {
            let pt = Geo.point(center: center, pixelRadius: radius, rangeNM: range,
                               distanceNM: sel.distanceNM, bearingDeg: sel.bearingDeg)
            let r: CGFloat = 9
            ctx.stroke(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                       with: .color(.white), lineWidth: 1.4)
        }

        // Centre ("you")
        let dot = CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)
        ctx.fill(Path(ellipseIn: dot), with: .color(.white))
        ctx.stroke(Path(ellipseIn: dot.insetBy(dx: -3, dy: -3)),
                   with: .color(.white.opacity(0.5)), lineWidth: 0.8)
    }

    /// A small triangle pointing along `headingDeg` (clockwise from north).
    private func triangle(at p: CGPoint, headingDeg: Double, size: CGFloat) -> Path {
        let a = headingDeg * .pi / 180
        func vec(_ ang: Double, _ len: CGFloat) -> CGPoint {
            CGPoint(x: p.x + len * sin(ang), y: p.y - len * cos(ang))
        }
        var path = Path()
        path.move(to: vec(a, size * 1.4))     // nose
        path.addLine(to: vec(a + 2.5, size))  // left tail
        path.addLine(to: vec(a - 2.5, size))  // right tail
        path.closeSubpath()
        return path
    }
}

// MARK: - Nearest‑traffic list

struct FlightList: View {
    var scene: RadarScene
    var limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if scene.aircraft.isEmpty {
                Text(scene.failed ? "Signal lost" : "No aircraft in range")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(scene.aircraft.prefix(limit)) { p in
                    HStack(spacing: 6) {
                        Circle().fill(AircraftStyle.color(for: p)).frame(width: 6, height: 6)
                        Text(p.displayName)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(AircraftStyle.altLabel(for: p))
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        Text(String(format: "%.0fnm", p.distanceNM))
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            if !scene.locationIsFresh {
                Text("centre: fallback location")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange.opacity(0.85))
                    .padding(.top, 1)
            }
        }
        .foregroundStyle(.white)
    }
}
