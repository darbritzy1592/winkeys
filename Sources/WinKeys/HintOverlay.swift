// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import AppKit

/// A small, non-interactive card that says what the Windows shortcut just
/// pressed is called on macOS.
///
/// This is the part that makes WinKeys a teacher rather than a crutch: the goal
/// is for the user to stop needing it. It never takes focus and never blocks
/// the keystroke — the translation has already happened by the time it appears.
final class HintOverlay {
    private var window: NSWindow?
    private var hideTimer: Timer?
    private let label = NSTextField(labelWithString: "")

    func show(from: String, to: String) {
        let window = existingOrNewWindow()
        label.attributedStringValue = Self.text(from: from, to: to)
        label.sizeToFit()

        let padding = NSSize(width: 28, height: 18)
        let size = NSSize(width: label.frame.width + padding.width * 2,
                          height: label.frame.height + padding.height * 2)
        label.frame.origin = NSPoint(x: padding.width, y: padding.height)

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            window.setFrame(NSRect(x: frame.midX - size.width / 2,
                                   y: frame.minY + 90,
                                   width: size.width, height: size.height),
                            display: false)
        }
        window.alphaValue = 1
        window.orderFrontRegardless()

        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: false) { [weak self] _ in
            self?.fadeOut()
        }
    }

    private static func text(from: String, to: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let dim = NSColor.secondaryLabelColor
        let bright = NSColor.labelColor
        let font = NSFont.systemFont(ofSize: 15, weight: .medium)

        result.append(NSAttributedString(string: from,
            attributes: [.font: font, .foregroundColor: dim]))
        result.append(NSAttributedString(string: "  \(L10n.shared.s.onMacItIs)  ",
            attributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: dim]))
        result.append(NSAttributedString(string: to,
            attributes: [.font: NSFont.systemFont(ofSize: 17, weight: .semibold),
                         .foregroundColor: bright]))
        return result
    }

    private func existingOrNewWindow() -> NSWindow {
        if let window { return window }

        let window = NSWindow(contentRect: .zero, styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.ignoresMouseEvents = true          // never gets in the way
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.hasShadow = true

        let visual = NSVisualEffectView()
        if #available(macOS 10.14, *) {
            visual.material = .hudWindow
        }   // older systems keep the default material, which still blurs
        visual.state = .active
        visual.blendingMode = .behindWindow
        visual.wantsLayer = true
        visual.layer?.cornerRadius = 14
        visual.layer?.masksToBounds = true
        visual.autoresizingMask = [.width, .height]
        visual.addSubview(label)

        window.contentView = visual
        self.window = window
        return window
    }

    private func fadeOut() {
        guard let window else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            window.animator().alphaValue = 0
        } completionHandler: {
            window.orderOut(nil)
        }
    }
}
