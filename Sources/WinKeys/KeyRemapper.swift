// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import AppKit
import CoreGraphics

/// Rewrites Windows keyboard habits into their macOS equivalents.
///
/// Uses a session-level event tap in `.defaultTap` mode, which is what allows
/// modifying events rather than only observing them. No driver, no kernel
/// extension, no private API — only the Accessibility permission.
final class KeyRemapper {
    static let shared = KeyRemapper()

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    private(set) var isRunning = false
    /// Set by the UI; when false the tap stays installed but passes everything.
    var isEnabled = true

    /// Called on the main thread after a translation, for the teaching overlay.
    var onTranslate: ((_ from: String, _ to: String) -> Void)?

    private init() {}

    // MARK: - Lifecycle

    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }
        guard AXIsProcessTrusted() else { return false }

        let mask = (1 << CGEventType.keyDown.rawValue)
                 | (1 << CGEventType.keyUp.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let remapper = Unmanaged<KeyRemapper>.fromOpaque(refcon).takeUnretainedValue()
            return remapper.handle(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.source = source
        isRunning = true
        return true
    }

    func stop() {
        guard let tap, let source else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        CFMachPortInvalidate(tap)
        self.tap = nil
        self.source = nil
        isRunning = false
    }

    // MARK: - The hot path

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // macOS disables a tap that takes too long or that the user interrupts.
        // Without this the app silently stops working and looks broken.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard isEnabled, type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }
        // Never touch terminals, VMs or remote sessions.
        guard !FrontmostApp.shared.isExcluded else {
            return Unmanaged.passUnretained(event)
        }

        let code = event.getIntegerValueField(.keyboardEventKeycode)
        // Read the original flags before rewriting: the rule that matched can
        // only be identified by what the user actually pressed.
        let originalFlags = event.flags
        guard let translation = Mapping.translate(keyCode: code, flags: originalFlags) else {
            return Unmanaged.passUnretained(event)
        }
        let matched = Mapping.rules.first { $0.matches(keyCode: code, flags: originalFlags) }

        event.setIntegerValueField(.keyboardEventKeycode, value: translation.keyCode)
        event.flags = translation.flags

        // Announce once per press, not twice (keyDown and keyUp both translate).
        if type == .keyDown, let onTranslate, let matched {
            let from = matched.winShortcut
            let to = translation.macShortcut
            DispatchQueue.main.async { onTranslate(from, to) }
        }
        return Unmanaged.passUnretained(event)
    }
}
