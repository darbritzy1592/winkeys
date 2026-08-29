// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import AppKit

/// Name, version, licence and — the part that actually matters for an app that
/// reads every keystroke — a plain statement of what it does with them.
final class AboutWindow: NSWindowController {
    private static var shared: AboutWindow?

    static func present() {
        if let existing = shared {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = AboutWindow()
        shared = controller
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = "Acerca de \(AppInfo.name)"
        window.center()
        self.init(window: window)
        build()
    }

    private func build() {
        guard let window else { return }
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 26, left: 30, bottom: 22, right: 30)
        stack.translatesAutoresizingMaskIntoConstraints = false

        if let icon = NSApp.applicationIconImage {
            let view = NSImageView(image: icon)
            view.imageScaling = .scaleProportionallyUpOrDown
            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalToConstant: 68).isActive = true
            view.heightAnchor.constraint(equalToConstant: 68).isActive = true
            stack.addArrangedSubview(view)
        }

        let t = L10n.shared.s
        stack.addArrangedSubview(text(AppInfo.name, size: 22, weight: .semibold))
        stack.addArrangedSubview(text(t.versionLine(AppInfo.version, AppInfo.build),
                                      size: 11, color: .secondaryLabelColor))
        stack.addArrangedSubview(text(t.platforms,
                                      size: 11, color: .secondaryLabelColor))

        let line = NSBox(); line.boxType = .separator
        line.widthAnchor.constraint(equalToConstant: 340).isActive = true
        stack.addArrangedSubview(line)

        stack.addArrangedSubview(text(t.privacy, size: 11,
                                      color: .secondaryLabelColor, lines: 6))

        let line2 = NSBox(); line2.boxType = .separator
        line2.widthAnchor.constraint(equalToConstant: 340).isActive = true
        stack.addArrangedSubview(line2)

        stack.addArrangedSubview(text("\(t.createdBy) \(AppInfo.author)", size: 12))
        stack.addArrangedSubview(text(t.licensedUnder(AppInfo.license),
                                      size: 11, color: .secondaryLabelColor))

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        let repo = NSButton(title: t.viewCode, target: self, action: #selector(openRepo))
        repo.bezelStyle = .rounded
        let licence = NSButton(title: t.license, target: self, action: #selector(openLicense))
        licence.bezelStyle = .rounded
        buttons.addArrangedSubview(repo)
        buttons.addArrangedSubview(licence)
        stack.addArrangedSubview(buttons)

        let content = NSView(frame: window.contentLayoutRect)
        content.autoresizingMask = [.width, .height]
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor)
        ])
        window.contentView = content
    }

    @objc private func openRepo() { NSWorkspace.shared.open(AppInfo.repositoryURL) }
    @objc private func openLicense() {
        NSWorkspace.shared.open(URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!)
    }

    private func text(_ string: String, size: CGFloat,
                      weight: NSFont.Weight = .regular,
                      color: NSColor = .labelColor, lines: Int = 2) -> NSTextField {
        let field = NSTextField(labelWithString: string)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.textColor = color
        field.alignment = .center
        field.lineBreakMode = .byWordWrapping
        field.maximumNumberOfLines = lines
        field.preferredMaxLayoutWidth = 340
        return field
    }
}
