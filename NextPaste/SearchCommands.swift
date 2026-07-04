//
//  SearchCommands.swift
//  NextPaste
//
//  T003 — bridges the shared `focusSearch()` action (T002) from the focused window
//  into the app-level `Commands` so `Command-F` can invoke it. This does NOT register
//  a global hotkey: `Command-F` is a standard app menu command only.
//

import SwiftUI

/// FocusedValue key carrying the shared search-focus action from the focused
/// window's `HomeView`. `Commands` reads this to invoke `focusSearch()` without
/// owning any search state.
private struct SearchFocusActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var searchFocusAction: (() -> Void)? {
        get { self[SearchFocusActionKey.self] }
        set { self[SearchFocusActionKey.self] = newValue }
    }
}

/// T007/T009: carries the request-clear actions from the focused window's HomeView
/// so the app-level `HistoryClearCommands` can invoke them via keyboard shortcuts
/// (`Option-Command-Delete`, `Shift-Option-Command-Delete`).
private struct RequestClearUnpinnedActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct RequestClearAllActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var requestClearUnpinnedAction: (() -> Void)? {
        get { self[RequestClearUnpinnedActionKey.self] }
        set { self[RequestClearUnpinnedActionKey.self] = newValue }
    }

    var requestClearAllAction: (() -> Void)? {
        get { self[RequestClearAllActionKey.self] }
        set { self[RequestClearAllActionKey.self] = newValue }
    }
}

/// App-level commands for search. Places `Find…` in the Edit menu after the text
/// editing group and binds it to `Command-F`. The command invokes the focused
/// window's `searchFocusAction` (published by `HomeView`); if no window is
/// focused or no action is published, the command is a no-op.
struct SearchCommands: Commands {
    @FocusedValue(\.searchFocusAction) private var searchFocusAction: (() -> Void)?

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Find…") {
                searchFocusAction?()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(searchFocusAction == nil)
        }
    }
}

/// T007/T009: app-level commands for clearing history. Binds
/// `Option-Command-Delete` (clear unpinned) and `Shift-Option-Command-Delete`
/// (clear all) to the focused window's request-clear actions. These are app menu
/// commands, not global hotkeys. The actual confirmation UI and clearing are owned
/// by `HomeView`.
struct HistoryClearCommands: Commands {
    @FocusedValue(\.requestClearUnpinnedAction) private var requestClearUnpinned: (() -> Void)?
    @FocusedValue(\.requestClearAllAction) private var requestClearAll: (() -> Void)?

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Divider()
            Button("Clear Unpinned History…") {
                requestClearUnpinned?()
            }
            .keyboardShortcut(.delete, modifiers: [.command, .option])
            .disabled(requestClearUnpinned == nil)

            Button("Clear All History…") {
                requestClearAll?()
            }
            .keyboardShortcut(.delete, modifiers: [.command, .option, .shift])
            .disabled(requestClearAll == nil)
        }
    }
}