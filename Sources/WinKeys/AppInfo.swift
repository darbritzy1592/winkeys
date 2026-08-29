// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import Foundation

enum AppInfo {
    static let name = "WinKeys"
    static let author = "neural-beat"
    static let license = "GPL-3.0-or-later"
    static let repository = "neural-beat/winkeys"
    static var repositoryURL: URL { URL(string: "https://github.com/\(repository)")! }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
}
