//
//  RowActionTraceGate.swift
//  NextPaste
//

import Foundation

#if DEBUG
enum RowActionTraceEnablementSource: String, Sendable {
    case uiTest = "ui-test"
    case manual
    case debug
}

struct RowActionTraceGateResolution: Equatable, Sendable {
    let isEnabled: Bool
    let source: RowActionTraceEnablementSource?
}

enum RowActionTraceGate {
    static let launchArgument = "-row-action-trace-enabled"
    static let environmentKey = "NEXTPASTE_ROW_ACTION_TRACE"
    private static let truthyValues: Set<String> = ["1", "true", "yes", "enabled", "on"]

    static var isEnabled: Bool {
        resolve().isEnabled
    }

    static func resolve(processInfo: ProcessInfo = .processInfo) -> RowActionTraceGateResolution {
        if processInfo.arguments.contains(launchArgument) {
            return RowActionTraceGateResolution(isEnabled: true, source: source(from: processInfo))
        }

        guard let rawValue = processInfo.environment[environmentKey],
              isTruthy(rawValue) else {
            return RowActionTraceGateResolution(isEnabled: false, source: nil)
        }

        return RowActionTraceGateResolution(isEnabled: true, source: source(from: processInfo))
    }

    private static func source(from processInfo: ProcessInfo) -> RowActionTraceEnablementSource {
        let environment = processInfo.environment
        if processInfo.arguments.contains("-ui-testing") {
            return .uiTest
        }

        if environment["UITEST_MODE"] == "1" || environment["NEXTPASTE_UI_TESTING"] == "1" {
            return .uiTest
        }

        if environment["NEXTPASTE_ROW_ACTION_TRACE_SOURCE"] == RowActionTraceEnablementSource.manual.rawValue {
            return .manual
        }

        return .debug
    }

    private static func isTruthy(_ rawValue: String) -> Bool {
        let normalizedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return truthyValues.contains(normalizedValue)
    }
}
#endif
