//
//  RowActionTraceClock.swift
//  NextPaste
//

import Foundation

#if DEBUG
struct RowActionTraceClock: Sendable {
    typealias MonotonicNanoseconds = UInt64

    let startedAtMonotonic: MonotonicNanoseconds

    init(startedAtMonotonic: MonotonicNanoseconds = Self.now()) {
        self.startedAtMonotonic = startedAtMonotonic
    }

    func elapsedNanoseconds() -> MonotonicNanoseconds {
        let current = Self.now()
        guard current >= startedAtMonotonic else {
            return 0
        }

        return current - startedAtMonotonic
    }

    static func now() -> MonotonicNanoseconds {
        DispatchTime.now().uptimeNanoseconds
    }
}

final class RowActionTraceSequence {
    typealias Value = UInt64

    private var current: Value

    init(startingAt current: Value = 0) {
        self.current = current
    }

    func next() -> Value {
        current += 1
        return current
    }
}
#endif
