// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 neural-beat

import Foundation

/// Virtual keycodes we care about, from Carbon's `Events.h`.
/// Named rather than inlined so the mapping table below reads as intent.
enum Key {
    static let a: Int64 = 0
    static let s: Int64 = 1
    static let z: Int64 = 6
    static let x: Int64 = 7
    static let c: Int64 = 8
    static let v: Int64 = 9
    static let f: Int64 = 3
    static let y: Int64 = 16
    static let n: Int64 = 45
    static let p: Int64 = 35
    static let o: Int64 = 31

    static let left: Int64 = 123
    static let right: Int64 = 124
    static let down: Int64 = 125
    static let up: Int64 = 126

    static let home: Int64 = 115
    static let end: Int64 = 119
    static let pageUp: Int64 = 116
    static let pageDown: Int64 = 121
}
