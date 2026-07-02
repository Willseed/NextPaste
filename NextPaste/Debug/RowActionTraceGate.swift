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

enum RowActionTraceGate {
    static let launchArgument = "-row-action-trace-enabled"
    static let environmentKey = "NEXTPASTE_ROW_ACTION_TRACE"

    static var isEnabled: Bool {
        false
    }
}
#endif
