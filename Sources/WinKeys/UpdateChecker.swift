// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import Foundation

/// Asks GitHub whether a newer release exists. Never downloads or installs
/// anything on its own: it points the user at the release page and lets them
/// decide. Only runs when asked.
enum UpdateChecker {
    enum Result {
        case upToDate(current: String)
        case available(version: String, url: URL)
        case failed(String)
    }

    private struct Release: Decodable {
        let tag_name: String
        let html_url: String
        let draft: Bool
        let prerelease: Bool
    }

    static func check(completion: @escaping (Result) -> Void) {
        let endpoint = URL(string: "https://api.github.com/repos/\(AppInfo.repository)/releases/latest")!
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieAcceptPolicy = .never
        URLSession(configuration: configuration).dataTask(with: request) { data, response, error in
            let finish = { (r: Result) in DispatchQueue.main.async { completion(r) } }

            if let error {
                finish(.failed(error.localizedDescription)); return
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                // No releases published yet: not an error worth alarming anyone with.
                finish(.upToDate(current: AppInfo.version)); return
            }
            guard let data, let release = try? JSONDecoder().decode(Release.self, from: data) else {
                finish(.failed("Respuesta inesperada de GitHub")); return
            }
            guard !release.draft, !release.prerelease else {
                finish(.upToDate(current: AppInfo.version)); return
            }

            let latest = release.tag_name.hasPrefix("v")
                ? String(release.tag_name.dropFirst())
                : release.tag_name
            if isNewer(latest, than: AppInfo.version),
               let url = URL(string: release.html_url) {
                finish(.available(version: latest, url: url))
            } else {
                finish(.upToDate(current: AppInfo.version))
            }
        }.resume()
    }

    /// Compares dotted versions numerically, so 0.10.0 beats 0.9.0.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
