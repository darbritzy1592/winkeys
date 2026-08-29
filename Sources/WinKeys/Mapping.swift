// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import CoreGraphics

/// What a Windows habit should become on macOS.
struct Translation {
    let keyCode: Int64
    let flags: CGEventFlags
    /// Shown in the "what you just pressed" hint. Mac notation.
    let macShortcut: String
}

/// A rule matches a keypress the user made out of Windows muscle memory.
struct Rule {
    let keyCode: Int64
    /// Modifiers that must be held, ignoring the ones in `ignoring`.
    let requires: CGEventFlags
    /// Modifiers that must NOT be held.
    let forbids: CGEventFlags
    let produces: Translation
    /// Human label for the hint overlay, in Windows notation.
    let winShortcut: String

    func matches(keyCode code: Int64, flags: CGEventFlags) -> Bool {
        guard code == keyCode else { return false }
        guard flags.isSuperset(of: requires) else { return false }
        return flags.intersection(forbids).isEmpty
    }
}

enum Mapping {
    /// Ctrl on Windows is Command on macOS for every editing verb.
    /// Shift is deliberately absent from `forbids` so Ctrl+Shift+Z still works.
    private static func ctrlToCmd(_ key: Int64, _ letter: String) -> Rule {
        Rule(keyCode: key,
             requires: .maskControl,
             forbids: [.maskCommand, .maskAlternate],
             produces: Translation(keyCode: key, flags: .maskCommand,
                                   macShortcut: "⌘\(letter)"),
             winShortcut: "Ctrl+\(letter)")
    }

    /// The editing verbs. Deliberately conservative: no Ctrl+W or Ctrl+T,
    /// which already mean something in browsers and would be a net loss.
    static let rules: [Rule] = [
        ctrlToCmd(Key.c, "C"),
        ctrlToCmd(Key.v, "V"),
        ctrlToCmd(Key.x, "X"),
        ctrlToCmd(Key.z, "Z"),
        ctrlToCmd(Key.a, "A"),
        ctrlToCmd(Key.s, "S"),
        ctrlToCmd(Key.f, "F"),
        ctrlToCmd(Key.p, "P"),
        ctrlToCmd(Key.o, "O"),
        ctrlToCmd(Key.n, "N"),

        // Windows redo is Ctrl+Y; macOS redo is Cmd+Shift+Z.
        Rule(keyCode: Key.y,
             requires: .maskControl,
             forbids: [.maskCommand, .maskAlternate],
             produces: Translation(keyCode: Key.z, flags: [.maskCommand, .maskShift],
                                   macShortcut: "⌘⇧Z"),
             winShortcut: "Ctrl+Y"),

        // Home/End mean line start/end on Windows. On macOS they jump the
        // whole document, which is the single most disorienting difference.
        Rule(keyCode: Key.home,
             requires: [],
             forbids: [.maskControl, .maskCommand],
             produces: Translation(keyCode: Key.left, flags: .maskCommand,
                                   macShortcut: "⌘←"),
             winShortcut: "Inicio"),
        Rule(keyCode: Key.end,
             requires: [],
             forbids: [.maskControl, .maskCommand],
             produces: Translation(keyCode: Key.right, flags: .maskCommand,
                                   macShortcut: "⌘→"),
             winShortcut: "Fin"),

        // Ctrl+Home/End is document start/end on Windows.
        Rule(keyCode: Key.home,
             requires: .maskControl,
             forbids: [.maskCommand],
             produces: Translation(keyCode: Key.up, flags: .maskCommand,
                                   macShortcut: "⌘↑"),
             winShortcut: "Ctrl+Inicio"),
        Rule(keyCode: Key.end,
             requires: .maskControl,
             forbids: [.maskCommand],
             produces: Translation(keyCode: Key.down, flags: .maskCommand,
                                   macShortcut: "⌘↓"),
             winShortcut: "Ctrl+Fin"),
    ]

    /// Returns the rewrite for a keypress, or nil to leave it alone.
    /// Shift is carried across so Ctrl+Shift+arrow keeps selecting.
    static func translate(keyCode: Int64, flags: CGEventFlags) -> Translation? {
        guard let rule = rules.first(where: { $0.matches(keyCode: keyCode, flags: flags) }) else {
            return nil
        }
        var produced = rule.produces.flags
        if flags.contains(.maskShift) { produced.insert(.maskShift) }
        return Translation(keyCode: rule.produces.keyCode,
                           flags: produced,
                           macShortcut: rule.produces.macShortcut)
    }
}
