// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import Foundation

/// Two languages, chosen by the user rather than by the system.
///
/// A switcher may well be running an English macOS while thinking in Spanish,
/// so the app's language is its own setting. Strings live in code instead of
/// .lproj bundles: with two languages this is simpler to read, impossible to
/// desynchronise, and adding a third means adding one `Strings` value.
enum Language: String, CaseIterable {
    case es, en

    var displayName: String {
        switch self {
        case .es: return "Español"
        case .en: return "English"
        }
    }

    /// First run follows the system, so most people never touch the setting.
    static var systemDefault: Language {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("es") ? .es : .en
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("WinKeysLanguageChanged")
}

final class L10n {
    static let shared = L10n()
    private let key = "language"

    var language: Language {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let value = Language(rawValue: raw) else { return .systemDefault }
            return value
        }
        set {
            guard newValue != language else { return }
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }

    var s: Strings { language == .es ? .spanish : .english }
    private init() {}
}

struct Strings {
    // Menu
    let stateActive, statePaused, stateNoPermission, stateFailed: String
    let translateShortcuts, teachEquivalent, openAtLogin: String
    let excludedApps: (Int) -> String
    let checkUpdates, showWelcome, about, grantAccess, quit, languageMenu: String

    // Welcome
    let welcomeTitle, tagline: String
    let bulletShortcuts, bulletHomeEnd, bulletTeaches, bulletExclusions: String
    let permissionNeeded, permissionGranted, openSystemSettings, start: String

    // About
    let versionLine: (String, String) -> String
    let platforms, createdBy: String
    let licensedUnder: (String) -> String
    let viewCode, license, privacy: String

    // Overlay and updates
    let onMacItIs: String
    let upToDateTitle: String
    let upToDateBody: (String) -> String
    let updateTitle: (String) -> String
    let updateBody: (String) -> String
    let viewRelease, notNow, ok, checkFailed: String

    static let spanish = Strings(
        stateActive: "Activo",
        statePaused: "En pausa",
        stateNoPermission: "Falta permiso de Accesibilidad",
        stateFailed: "No se pudo iniciar",
        translateShortcuts: "Traducir atajos de Windows",
        teachEquivalent: "Enseñarme el equivalente de Mac",
        openAtLogin: "Abrir al iniciar sesión",
        excludedApps: { "Excluidas: \($0) apps (terminales, VMs)" },
        checkUpdates: "Buscar actualizaciones…",
        showWelcome: "Ver la bienvenida…",
        about: "Acerca de WinKeys…",
        grantAccess: "Conceder acceso…",
        quit: "Salir de WinKeys",
        languageMenu: "Idioma",

        welcomeTitle: "WinKeys",
        tagline: "Tus atajos de Windows, funcionando en el Mac.",
        bulletShortcuts: "Ctrl+C, Ctrl+V, Ctrl+Z y los demás hacen lo que esperas.",
        bulletHomeEnd: "Inicio y Fin van al principio y al final de la línea.",
        bulletTeaches: "Te enseña el equivalente de Mac, para que dejes de necesitarla.",
        bulletExclusions: "No toca terminales, editores ni máquinas virtuales.",
        permissionNeeded: "Para leer el teclado necesita permiso de Accesibilidad.",
        permissionGranted: "Permiso concedido. WinKeys ya está funcionando.",
        openSystemSettings: "Abrir Ajustes del Sistema",
        start: "Empezar",

        versionLine: { "Versión \($0) (\($1))" },
        platforms: "Intel y Apple Silicon · macOS 10.13 o posterior",
        createdBy: "Creado por",
        licensedUnder: { "Software libre bajo licencia \($0)" },
        viewCode: "Ver el código",
        license: "Licencia",
        privacy: """
            WinKeys lee las teclas que pulsas para poder traducirlas, y nada más. \
            No guarda lo que escribes, no lo envía a ningún sitio y no se conecta \
            a internet salvo cuando tú buscas actualizaciones. El código es \
            público y cualquiera puede comprobarlo.
            """,

        onMacItIs: "en Mac es",
        upToDateTitle: "WinKeys está al día",
        upToDateBody: { "Tienes la versión \($0)." },
        updateTitle: { "Hay una versión nueva: \($0)" },
        updateBody: { "Tienes la \($0). WinKeys no instala nada por su cuenta: abre la página y decides tú." },
        viewRelease: "Ver la versión",
        notNow: "Ahora no",
        ok: "Vale",
        checkFailed: "No se pudo comprobar"
    )

    static let english = Strings(
        stateActive: "Active",
        statePaused: "Paused",
        stateNoPermission: "Accessibility permission missing",
        stateFailed: "Could not start",
        translateShortcuts: "Translate Windows shortcuts",
        teachEquivalent: "Teach me the Mac equivalent",
        openAtLogin: "Open at login",
        excludedApps: { "Excluded: \($0) apps (terminals, VMs)" },
        checkUpdates: "Check for Updates…",
        showWelcome: "Show Welcome…",
        about: "About WinKeys…",
        grantAccess: "Grant Access…",
        quit: "Quit WinKeys",
        languageMenu: "Language",

        welcomeTitle: "WinKeys",
        tagline: "Your Windows shortcuts, working on the Mac.",
        bulletShortcuts: "Ctrl+C, Ctrl+V, Ctrl+Z and the rest do what you expect.",
        bulletHomeEnd: "Home and End go to the start and end of the line.",
        bulletTeaches: "It teaches you the Mac equivalent, so you stop needing it.",
        bulletExclusions: "It stays out of terminals, editors and virtual machines.",
        permissionNeeded: "Reading the keyboard needs the Accessibility permission.",
        permissionGranted: "Permission granted. WinKeys is running.",
        openSystemSettings: "Open System Settings",
        start: "Start",

        versionLine: { "Version \($0) (\($1))" },
        platforms: "Intel and Apple Silicon · macOS 10.13 or later",
        createdBy: "Created by",
        licensedUnder: { "Free software under the \($0) licence" },
        viewCode: "View the code",
        license: "Licence",
        privacy: """
            WinKeys reads the keys you press so it can translate them, and \
            nothing else. It does not store what you type, does not send it \
            anywhere, and only connects to the internet when you check for \
            updates. The code is public and anyone can verify it.
            """,

        onMacItIs: "on Mac is",
        upToDateTitle: "WinKeys is up to date",
        upToDateBody: { "You have version \($0)." },
        updateTitle: { "A new version is available: \($0)" },
        updateBody: { "You have \($0). WinKeys never installs anything on its own: it opens the page and you decide." },
        viewRelease: "View release",
        notNow: "Not now",
        ok: "OK",
        checkFailed: "Could not check"
    )
}
