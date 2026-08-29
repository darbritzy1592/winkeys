// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat
//
// Draws WinKeys.icns. The icon is a keycap: the Ctrl a Windows user reaches
// for, resolving into the Command it becomes on macOS.

import AppKit

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let out = "build/WinKeys.iconset"
try? FileManager.default.createDirectory(atPath: out,
                                         withIntermediateDirectories: true)

func draw(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }

    // macOS icons sit on a rounded superellipse inset from the canvas edge.
    let inset = s * 0.085
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.2237
    let body = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Keycap face: a cool slate that reads on both light and dark menu bars.
    ctx.saveGState()
    body.addClip()
    let colors = [NSColor(calibratedRed: 0.29, green: 0.36, blue: 0.51, alpha: 1).cgColor,
                  NSColor(calibratedRed: 0.16, green: 0.20, blue: 0.31, alpha: 1).cgColor]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: rect.minX, y: rect.maxY),
                           end: CGPoint(x: rect.maxX, y: rect.minY),
                           options: [])

    // Top bevel, so it reads as a physical key rather than a flat square.
    let bevel = NSBezierPath(roundedRect: rect.insetBy(dx: rect.width * 0.06,
                                                       dy: rect.height * 0.06),
                             xRadius: radius * 0.8, yRadius: radius * 0.8)
    NSColor.white.withAlphaComponent(0.10).setFill()
    bevel.fill()
    ctx.restoreGState()

    // The Command glyph, the answer the user is looking for.
    let glyph = "⌘"
    let fontSize = s * 0.46
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
        .foregroundColor: NSColor.white
    ]
    let str = NSAttributedString(string: glyph, attributes: attrs)
    let g = str.size()
    str.draw(at: NSPoint(x: (s - g.width) / 2, y: (s - g.height) / 2 - s * 0.02))

    // "Ctrl" whispered above it: only meaningful at large sizes, invisible clutter at 16px.
    if size >= 128 {
        let small: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: s * 0.105, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.45)
        ]
        let ctrl = NSAttributedString(string: "Ctrl", attributes: small)
        let c = ctrl.size()
        ctrl.draw(at: NSPoint(x: (s - c.width) / 2, y: s * 0.735))
    }

    image.unlockFocus()
    return image
}

for size in sizes {
    let image = draw(size: size)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }

    // iconutil expects both the 1x name and the @2x name of the half size.
    var names: [String] = []
    if [16, 32, 128, 256, 512].contains(size) { names.append("icon_\(size)x\(size).png") }
    if [32, 64, 256, 512, 1024].contains(size) {
        let half = size / 2
        names.append("icon_\(half)x\(half)@2x.png")
    }
    for name in names {
        try? png.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
    }
}
print("iconset written to \(out)")
