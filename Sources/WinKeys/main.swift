// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import AppKit

/// WinKeys — Windows keyboard habits, working on macOS.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let hint = HintOverlay()
    private var welcome: WelcomeWindow?

    private var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "enabled") }
    }
    private var teaching: Bool {
        get { UserDefaults.standard.object(forKey: "teaching") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "teaching") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildStatusItem()

        KeyRemapper.shared.onTranslate = { [weak self] from, to in
            guard self?.teaching == true else { return }
            self?.hint.show(from: from, to: to)
        }
        KeyRemapper.shared.isEnabled = enabled

        NotificationCenter.default.addObserver(
            forName: .languageChanged, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshMenu() }

        if !UserDefaults.standard.bool(forKey: "hasSeenWelcome") {
            showWelcome()
            return
        }
        if !requestAccessibilityIfNeeded() { return }
        startRemapper()
    }

    // MARK: - Permission

    /// Accessibility is the only permission WinKeys needs, and without it the
    /// event tap cannot be created at all.
    private func requestAccessibilityIfNeeded() -> Bool {
        if AXIsProcessTrusted() { return true }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        // The user grants it in System Settings, which happens outside the app,
        // so poll until it lands rather than making them relaunch.
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard AXIsProcessTrusted() else { return }
            timer.invalidate()
            self?.startRemapper()
            self?.refreshMenu()
        }
        return false
    }

    private func startRemapper() {
        if !KeyRemapper.shared.start() {
            NSLog("WinKeys: could not create the event tap")
        }
        refreshMenu()
    }

    // MARK: - Menu bar

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = Self.menuBarIcon()
        refreshMenu()
    }

    /// SF Symbols only exist from macOS 11. On older systems the ⌘ glyph is
    /// drawn as a template image, which looks native and costs nothing.
    private static func menuBarIcon() -> NSImage {
        if #available(macOS 11.0, *),
           let symbol = NSImage(systemSymbolName: "keyboard",
                                accessibilityDescription: AppInfo.name) {
            return symbol
        }
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.black
        ]
        let glyph = NSAttributedString(string: "⌘", attributes: attrs)
        let g = glyph.size()
        glyph.draw(at: NSPoint(x: (size.width - g.width) / 2,
                               y: (size.height - g.height) / 2))
        image.unlockFocus()
        image.isTemplate = true   // follows the menu bar's light/dark appearance
        return image
    }

    private func refreshMenu() {
        let menu = NSMenu()

        let t = L10n.shared.s
        let state: String
        if !AXIsProcessTrusted() {
            state = t.stateNoPermission
        } else if !KeyRemapper.shared.isRunning {
            state = t.stateFailed
        } else {
            state = enabled ? t.stateActive : t.statePaused
        }
        let header = NSMenuItem(title: "WinKeys — \(state)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let toggle = NSMenuItem(title: t.translateShortcuts,
                                action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        toggle.state = enabled ? .on : .off
        menu.addItem(toggle)

        let teach = NSMenuItem(title: t.teachEquivalent,
                               action: #selector(toggleTeaching), keyEquivalent: "")
        teach.target = self
        teach.state = teaching ? .on : .off
        menu.addItem(teach)

        menu.addItem(.separator())

        if !AXIsProcessTrusted() {
            let grant = NSMenuItem(title: t.grantAccess,
                                   action: #selector(openAccessibility), keyEquivalent: "")
            grant.target = self
            menu.addItem(grant)
            menu.addItem(.separator())
        }

        let excluded = NSMenuItem(
            title: t.excludedApps(Exclusions.all.count),
            action: nil, keyEquivalent: "")
        excluded.isEnabled = false
        menu.addItem(excluded)

        let login = NSMenuItem(title: t.openAtLogin,
                               action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())

        let updates = NSMenuItem(title: t.checkUpdates,
                                 action: #selector(checkForUpdates), keyEquivalent: "")
        updates.target = self
        menu.addItem(updates)

        let languageItem = NSMenuItem(title: t.languageMenu, action: nil, keyEquivalent: "")
        let languageMenu = NSMenu()
        for language in Language.allCases {
            let entry = NSMenuItem(title: language.displayName,
                                   action: #selector(selectLanguage(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = language.rawValue
            entry.state = (language == L10n.shared.language) ? .on : .off
            languageMenu.addItem(entry)
        }
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        let welcomeItem = NSMenuItem(title: t.showWelcome,
                                     action: #selector(reopenWelcome), keyEquivalent: "")
        welcomeItem.target = self
        menu.addItem(welcomeItem)

        let about = NSMenuItem(title: t.about,
                               action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: t.quit,
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        enabled.toggle()
        KeyRemapper.shared.isEnabled = enabled
        refreshMenu()
    }

    @objc private func toggleTeaching() {
        teaching.toggle()
        refreshMenu()
    }

    @objc private func toggleLoginItem() {
        LoginItem.setEnabled(!LoginItem.isEnabled)
        refreshMenu()
    }

    @objc private func showAbout() {
        AboutWindow.present()
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let language = Language(rawValue: raw) else { return }
        L10n.shared.language = language
    }

    @objc private func checkForUpdates() {
        let t = L10n.shared.s
        UpdateChecker.check { result in
            let alert = NSAlert()
            NSApp.activate(ignoringOtherApps: true)
            switch result {
            case .upToDate(let current):
                alert.messageText = t.upToDateTitle
                alert.informativeText = t.upToDateBody(current)
                alert.addButton(withTitle: t.ok)
            case .available(let version, let url):
                alert.messageText = t.updateTitle(version)
                alert.informativeText = t.updateBody(AppInfo.version)
                alert.addButton(withTitle: t.viewRelease)
                alert.addButton(withTitle: t.notNow)
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(url)
                }
                return
            case .failed(let reason):
                alert.messageText = t.checkFailed
                alert.informativeText = reason
                alert.addButton(withTitle: t.ok)
            }
            alert.runModal()
        }
    }

    @objc private func reopenWelcome() {
        showWelcome()
    }

    private func showWelcome() {
        welcome = WelcomeWindow { [weak self] in
            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            if !KeyRemapper.shared.isRunning { self?.startRemapper() }
            self?.refreshMenu()
            self?.welcome = nil
        }
        welcome?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
app.run()
