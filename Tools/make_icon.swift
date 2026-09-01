// Renders the app icon PNGs into PlaneRadarApp/Assets.xcassets/AppIcon.appiconset.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
//     xcrun swiftc -parse-as-library -O -o /tmp/icongen Tools/make_icon.swift
//   /tmp/icongen PlaneRadarApp/Assets.xcassets/AppIcon.appiconset
//
// Needs a full Xcode toolchain (SwiftUI macros + ImageRenderer).

import SwiftUI
import AppKit

// MARK: - Palette

private let radarGreen = Color(red: 0.30, green: 0.95, blue: 0.55)
private let bgInner    = Color(red: 0.055, green: 0.16, blue: 0.13)
private let bgOuter    = Color(red: 0.015, green: 0.045, blue: 0.04)

// MARK: - Artwork (authored on a 1024 canvas, squircle inset to 824)

struct AppIconArt: View {
    private let canvas: CGFloat = 1024
    private let plate: CGFloat = 824

    var body: some View {
        ZStack {
            Color.clear
            ZStack {
                RoundedRectangle(cornerRadius: 185, style: .continuous)
                    .fill(RadialGradient(colors: [bgInner, bgOuter],
                                         center: .center, startRadius: 30, endRadius: 620))
                    .overlay(
                        RoundedRectangle(cornerRadius: 185, style: .continuous)
                            .strokeBorder(.white.opacity(0.07), lineWidth: 3)
                    )

                Canvas { ctx, size in scope(&ctx, size) }
                    .padding(96)

                Image(systemName: "airplane")
                    .font(.system(size: 360, weight: .regular))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-45))
                    .shadow(color: radarGreen.opacity(0.6), radius: 26)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
                    .offset(x: 6, y: -4)
            }
            .frame(width: plate, height: plate)
            .shadow(color: .black.opacity(0.28), radius: 14, y: 12)
        }
        .frame(width: canvas, height: canvas)
    }

    private func scope(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let R = min(size.width, size.height) / 2

        // Sweep wedge
        var wedge = Path()
        wedge.move(to: c)
        wedge.addArc(center: c, radius: R, startAngle: .degrees(-90),
                     endAngle: .degrees(-26), clockwise: false)
        wedge.closeSubpath()
        ctx.fill(wedge, with: .radialGradient(
            Gradient(colors: [radarGreen.opacity(0.5), radarGreen.opacity(0)]),
            center: c, startRadius: 0, endRadius: R))

        // Range rings
        for f in [0.4, 0.7, 1.0] {
            let r = R * f
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                       with: .color(radarGreen.opacity(f == 1.0 ? 0.5 : 0.22)),
                       lineWidth: f == 1.0 ? 7 : 4)
        }

        // Cross hairs
        var cross = Path()
        cross.move(to: CGPoint(x: c.x - R, y: c.y)); cross.addLine(to: CGPoint(x: c.x + R, y: c.y))
        cross.move(to: CGPoint(x: c.x, y: c.y - R)); cross.addLine(to: CGPoint(x: c.x, y: c.y + R))
        ctx.stroke(cross, with: .color(radarGreen.opacity(0.14)), lineWidth: 3)

        // A couple of contacts
        for p in [CGPoint(x: c.x - R * 0.46, y: c.y + R * 0.34),
                  CGPoint(x: c.x + R * 0.52, y: c.y + R * 0.12)] {
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 9, y: p.y - 9, width: 18, height: 18)),
                     with: .color(radarGreen))
        }
    }
}

// MARK: - Entry point

@main
enum IconGen {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        MainActor.assumeIsolated { run() }
    }

    @MainActor
    static func run() {
        let outDir = CommandLine.arguments.dropFirst().first ?? "."
        let art = AppIconArt()

        for px in [16, 32, 64, 128, 256, 512, 1024] {
            let renderer = ImageRenderer(content: art)
            renderer.scale = CGFloat(px) / 1024.0
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                FileHandle.standardError.write(Data("render failed at \(px)px\n".utf8))
                continue
            }
            let url = URL(fileURLWithPath: outDir).appendingPathComponent("icon_\(px).png")
            do {
                try png.write(to: url)
                print("wrote \(url.lastPathComponent)  \(png.count) bytes")
            } catch {
                FileHandle.standardError.write(Data("write failed \(url.path): \(error)\n".utf8))
            }
        }
    }
}
