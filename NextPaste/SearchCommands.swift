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