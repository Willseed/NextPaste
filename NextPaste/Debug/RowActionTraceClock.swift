//
//  RowActionTraceClock.swift
//  NextPaste
//

import Foundation

#if DEBUG
struct RowActionTraceClock: Sendable {
    typealias MonotonicNanoseconds = UInt64
}

struct RowActionTraceSequence: Sendable {
    typealias Value = UInt64
}
#endif
