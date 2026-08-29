// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import AppKit

/// Apps where translating Ctrl would break something the user needs.
///
/// This is the most important list in the app. In a terminal Ctrl+C means
/// "interrupt", not "copy"; in a virtual machine or a remote session the guest
/// OS already speaks Windows and expects the real Ctrl. Getting this wrong once
/// costs the user's trust permanently, so the default list is broad and the
/// user can add to it.
enum Exclusions {
    static let builtIn: Set<String> = [
        // Terminals
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "io.alacritty",
        "net.kovidgoyal.kitty",
        "co.zeit.hyper",
        "com.github.wez.wezterm",
        "org.tabby",

        // Editors with their own terminal built in
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "com.todesktop.230313mzl4w4u92",   // Cursor
        "com.jetbrains.intellij",
        "com.sublimetext.4",
        "dev.zed.Zed",

        // Virtual machines and remote sessions: the guest already is Windows
        "com.parallels.desktop.console",
        "com.vmware.fusion",
        "com.utmapp.UTM",
        "org.virtualbox.app.VirtualBox",
        "com.microsoft.rdc.macos",
        "com.apple.ScreenSharing",
        "com.teamviewer.TeamViewer",
        "com.anydesk.anydeskmac",

        // Remote/SSH clients
        "com.termius.mac",
    ]

    private static let defaultsKey = "userExcludedBundleIDs"

    static var userExcluded: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: defaultsKey) }
    }

    static var all: Set<String> { builtIn.union(userExcluded) }

    static func contains(_ bundleID: String?) -> Bool {
        guard let bundleID else { return true }   // unknown app: stay out of the way
        return all.contains(bundleID)
    }
}

/// Tracks the frontmost app without asking on every keystroke.
///
/// `NSWorkspace.frontmostApplication` is far too slow to call inside an event
/// tap callback, which runs on the path of every key the user presses. The
/// activation notification gives the same answer for free.
final class FrontmostApp {
    static let shared = FrontmostApp()

    private(set) var bundleID: String?

    private init() {
        bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication
            self?.bundleID = app?.bundleIdentifier
        }
    }

    var isExcluded: Bool { Exclusions.contains(bundleID) }
}
