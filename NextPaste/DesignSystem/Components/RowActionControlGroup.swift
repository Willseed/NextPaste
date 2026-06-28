//
//  RowActionControlGroup.swift
//  NextPaste
//

import SwiftUI

struct RowActionControlGroup: View {
    static let copyButtonIdentifier = "copy-clip-button"
    static let pinButtonIdentifier = "pin-clip-button"
    static let deleteButtonIdentifier = "delete-clip-button"

    let isPinned: Bool
    let showsDeleteAction: Bool
    let showsPinAction: Bool
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    static func visibleActionIdentifiers(
        includesCopyAction: Bool,
        showsPinAction: Bool,
        showsDeleteAction: Bool
    ) -> [String] {
        var identifiers = [String]()

        if includesCopyAction {
            identifiers.append(copyButtonIdentifier)
        }

        if showsPinAction {
            identifiers.append(pinButtonIdentifier)
        }

        if showsDeleteAction {
            identifiers.append(deleteButtonIdentifier)
        }

        return identifiers
    }

    var body: some View {
        if let onCopy {
            actionButton(
                .copy,
                identifier: Self.copyButtonIdentifier,
                action: onCopy
            )
        }

        if showsPinAction, let onTogglePin {
            actionButton(
                .pin(isPinned: isPinned),
                identifier: Self.pinButtonIdentifier,
                action: onTogglePin
            )
        }

        if showsDeleteAction, let onDelete {
            actionButton(
                .delete,
                identifier: Self.deleteButtonIdentifier,
                role: .destructive,
                action: onDelete
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
            Label(action.accessibilityLabel, systemImage: action.symbolName)
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(action.accessibilityLabel)
    }
}
