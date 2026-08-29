// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import AppKit

/// Starts WinKeys when the user logs in.
///
/// Implemented as a LaunchAgent rather than `SMAppService`, which only exists
/// from macOS 13. A plist in ~/Library/LaunchAgents works identically from
/// 10.13 onwards and still appears in System Settings › Login Items on modern
/// versions, so there is one code path instead of two.
enum LoginItem {
    private static let label = "com.winkeys.app.launcher"

    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    /// The .app bundle, not the inner binary: launching the bundle keeps the
    /// app's identity, and with it its Accessibility permission.
    private static var appPath: String {
        Bundle.main.bundlePath
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        enabled ? enable() : disable()
    }

    private static func enable() -> Bool {
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": ["/usr/bin/open", "-a", appPath],
            "RunAtLoad": true,
            "LimitLoadToSessionType": "Aqua"
        ]
        do {
            try FileManager.default.createDirectory(
                at: plistURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: plist,
                                                          format: .xml, options: 0)
            try data.write(to: plistURL)
            return true
        } catch {
            NSLog("WinKeys: could not write the login item: \(error)")
            return false
        }
    }

    private static func disable() -> Bool {
        guard isEnabled else { return true }
        do {
            try FileManager.default.removeItem(at: plistURL)
            return true
        } catch {
            NSLog("WinKeys: could not remove the login item: \(error)")
            return false
        }
    }
}
