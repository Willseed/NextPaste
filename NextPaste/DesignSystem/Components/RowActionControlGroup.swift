//
//  RowActionControlGroup.swift
//  NextPaste
//

import SwiftUI

struct RowActionControlGroup: View {
    static let copyButtonIdentifier = "copy-clip-button"
    static let pinButtonIdentifier = "pin-clip-button"
    static let deleteButtonIdentifier = "delete-clip-button"

    let onCopy: (() -> Void)?

    static func visibleActionIdentifiers(includesCopyAction: Bool) -> [String] {
        includesCopyAction ? [copyButtonIdentifier] : []
    }

    static func accessibilityActionLabels(
        isPinned: Bool,
        includesCopyAction: Bool = true
    ) -> [String] {
        var labels: [String] = []
        if includesCopyAction {
            labels.append(ClipboardRowPresentation.RowAction.copy.accessibilityLabel)
        }
        labels.append(pinActionLabel(isPinned: isPinned))
        labels.append(deleteActionLabel)
        return labels
    }

    static func pinActionLabel(isPinned: Bool) -> String {
        ClipboardRowPresentation.RowAction.pin(isPinned: isPinned).accessibilityLabel
    }

    static func pinActionSymbolName(isPinned: Bool) -> String {
        ClipboardRowPresentation.RowAction.pin(isPinned: isPinned).symbolName
    }

    static var deleteActionLabel: String {
        ClipboardRowPresentation.RowAction.delete.accessibilityLabel
    }

    static var deleteActionSymbolName: String {
        ClipboardRowPresentation.RowAction.delete.symbolName
    }

    var body: some View {
        if let onCopy {
            actionButton(
                .copy,
                identifier: Self.copyButtonIdentifier,
                action: onCopy
            )
        }
    }

    private func actionButton(
        _ action: ClipboardRowPresentation.RowAction,
        identifier: String,
        role: ButtonRole? = nil,
        action handler: @escaping () -> Void
    ) -> some View {
        Button(role: role) {
            handler()
        } label: {
            Label(LocalizedStringKey(action.accessibilityLabel), systemImage: action.symbolName)
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(Text(LocalizedStringKey(action.accessibilityLabel)))
    }
}
