// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import AppKit

/// Shown once, on first launch. Its whole job is to get the user from
/// "installed" to "working", which means one thing: the Accessibility
/// permission. Everything else is context so that granting it feels reasonable
/// rather than alarming.
final class WelcomeWindow: NSWindowController, NSWindowDelegate {
    private var pollTimer: Timer?
    private var statusLabel: NSTextField!
    private var grantButton: NSButton!
    private var settingsButton: NSButton!
    private var languagePicker: NSSegmentedControl!
    private var contentStack: NSStackView!
    private var onFinish: (() -> Void)?

    convenience init(onFinish: @escaping () -> Void) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 470),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = "Bienvenido a \(AppInfo.name)"
        window.center()
        self.init(window: window)
        self.onFinish = onFinish
        window.delegate = self
        buildContent()
    }

    private func buildContent() {
        guard let window else { return }
        let content = NSView(frame: window.contentLayoutRect)
        content.autoresizingMask = [.width, .height]

        let stack = NSStackView()
        contentStack = stack
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 34, bottom: 24, right: 34)
        stack.translatesAutoresizingMaskIntoConstraints = false

        languagePicker = NSSegmentedControl(
            labels: Language.allCases.map(\.displayName),
            trackingMode: .selectOne,
            target: self, action: #selector(changeLanguage))
        languagePicker.selectedSegment =
            Language.allCases.firstIndex(of: L10n.shared.language) ?? 0
        languagePicker.controlSize = .small
        stack.addArrangedSubview(languagePicker)

        if let icon = NSApp.applicationIconImage {
            let view = NSImageView(image: icon)
            view.imageScaling = .scaleProportionallyUpOrDown
            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalToConstant: 76).isActive = true
            view.heightAnchor.constraint(equalToConstant: 76).isActive = true
            stack.addArrangedSubview(view)
        }

        let t = L10n.shared.s
        stack.addArrangedSubview(label(t.welcomeTitle,
                                       font: .systemFont(ofSize: 24, weight: .semibold)))
        stack.addArrangedSubview(label(t.tagline,
                                       font: .systemFont(ofSize: 13),
                                       color: .secondaryLabelColor))

        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(bullet("⌘", t.bulletShortcuts))
        stack.addArrangedSubview(bullet("↔", t.bulletHomeEnd))
        stack.addArrangedSubview(bullet("✳", t.bulletTeaches))
        stack.addArrangedSubview(bullet("⛔", t.bulletExclusions))
        stack.addArrangedSubview(separator())

        statusLabel = label(t.permissionNeeded,
                            font: .systemFont(ofSize: 12),
                            color: .secondaryLabelColor)
        statusLabel.alignment = .center
        stack.addArrangedSubview(statusLabel)

        grantButton = NSButton(title: t.grantAccess, target: self,
                               action: #selector(grant))
        grantButton.bezelStyle = .rounded
        grantButton.keyEquivalent = "\r"
        stack.addArrangedSubview(grantButton)

        // A second, explicit way in: the system prompt only appears once per
        // app, so anyone who dismissed it would otherwise be stuck with no
        // visible route to the setting.
        settingsButton = NSButton(title: t.openSystemSettings, target: self,
                                  action: #selector(openSettings))
        settingsButton.bezelStyle = .inline
        settingsButton.isBordered = false
        if #available(macOS 10.14, *) {
            settingsButton.contentTintColor = .linkColor
        } else {
            settingsButton.attributedTitle = NSAttributedString(
                string: t.openSystemSettings,
                attributes: [.foregroundColor: NSColor.linkColor,
                             .font: NSFont.systemFont(ofSize: 12)])
        }
        stack.addArrangedSubview(settingsButton)

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor)
        ])
        window.contentView = content
        refresh()
    }

    // MARK: - Permission flow

    @objc private func grant() {
        if AXIsProcessTrusted() { finish(); return }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        startPolling()
    }

    /// The permission is granted in System Settings, outside this app, so watch
    /// for it instead of making the user come back and press something again.
    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard AXIsProcessTrusted() else { return }
            timer.invalidate()
            self?.refresh()
        }
    }

    private func refresh() {
        let t = L10n.shared.s
        if AXIsProcessTrusted() {
            statusLabel.stringValue = t.permissionGranted
            statusLabel.textColor = .systemGreen
            grantButton.title = t.start
            grantButton.action = #selector(finish)
            settingsButton.isHidden = true
        } else {
            statusLabel.stringValue = t.permissionNeeded
            statusLabel.textColor = .secondaryLabelColor
            grantButton.title = t.grantAccess
            grantButton.action = #selector(grant)
            settingsButton.isHidden = false
            settingsButton.title = t.openSystemSettings
        }
        grantButton.target = self
    }

    @objc private func openSettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        startPolling()
    }

    @objc private func changeLanguage() {
        let index = languagePicker.selectedSegment
        guard index >= 0, index < Language.allCases.count else { return }
        L10n.shared.language = Language.allCases[index]
        rebuild()
    }

    /// Rebuilding is simpler and less error-prone than reassigning every label.
    private func rebuild() {
        contentStack.removeFromSuperview()
        buildContent()
    }

    @objc private func finish() {
        pollTimer?.invalidate()
        let callback = onFinish
        onFinish = nil          // never run twice: the close below calls back in
        callback?()
        close()
    }

    /// Dismissing with the close button must not leave the app inert with no
    /// way back. Treat it as finishing: the menu bar item is still there, and
    /// the welcome can be reopened from it.
    func windowWillClose(_ notification: Notification) {
        pollTimer?.invalidate()
        let callback = onFinish
        onFinish = nil
        callback?()
    }

    // MARK: - Small builders

    private func label(_ text: String, font: NSFont,
                       color: NSColor = .labelColor) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = font
        field.textColor = color
        field.alignment = .center
        field.lineBreakMode = .byWordWrapping
        field.maximumNumberOfLines = 3
        field.preferredMaxLayoutWidth = 380
        return field
    }

    private func bullet(_ symbol: String, _ text: String) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 10

        let mark = NSTextField(labelWithString: symbol)
        mark.font = .systemFont(ofSize: 13)
        mark.textColor = .secondaryLabelColor
        mark.setContentHuggingPriority(.required, for: .horizontal)
        mark.widthAnchor.constraint(equalToConstant: 16).isActive = true

        let body = NSTextField(labelWithString: text)
        body.font = .systemFont(ofSize: 12)
        body.lineBreakMode = .byWordWrapping
        body.maximumNumberOfLines = 2
        body.preferredMaxLayoutWidth = 340

        row.addArrangedSubview(mark)
        row.addArrangedSubview(body)
        row.widthAnchor.constraint(equalToConstant: 380).isActive = true
        return row
    }

    private func separator() -> NSView {
        let line = NSBox()
        line.boxType = .separator
        line.widthAnchor.constraint(equalToConstant: 380).isActive = true
        return line
    }
}
