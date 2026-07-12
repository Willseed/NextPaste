//
//  SearchCommands.swift
//  NextPaste
//
//  T003 — bridges the shared `focusSearch()` action (T002) from the focused window
//  into the app-level `Commands` so `Command-F` can invoke it. This does NOT register
//  a global hotkey: `Command-F` is a standard app menu command only.
//

import SwiftUI

/// One stable scene-wide command payload. Publishing separate closure values from
/// `HomeView.body` recreated three identities whenever layout or selection changed,
/// which could make SwiftUI update its focused-value table repeatedly in one frame.
/// The dispatcher has stable reference identity and resolves each request against
/// the currently installed HomeView generation only when a command is invoked.
@MainActor
final class FocusedSceneCommandDispatcher {
    enum Request: Equatable {
        case focusSearch
        case clearUnpinnedHistory
        case clearAllHistory
    }

    private var owner: UUID?
    private var handler: ((Request) -> Void)?

    @discardableResult
    func install(_ handler: @escaping (Request) -> Void) -> UUID {
        let generation = UUID()
        owner = generation
        self.handler = handler
        return generation
    }

    func uninstall(owner generation: UUID) {
        guard owner == generation else { return }
        owner = nil
        handler = nil
    }

    func send(_ request: Request) {
        handler?(request)
    }
}

private struct FocusedSceneCommandDispatcherKey: FocusedValueKey {
    typealias Value = FocusedSceneCommandDispatcher
}

extension FocusedValues {
    var nextPasteCommandDispatcher: FocusedSceneCommandDispatcher? {
        get { self[FocusedSceneCommandDispatcherKey.self] }
        set { self[FocusedSceneCommandDispatcherKey.self] = newValue }
    }
}

/// App-level commands for search. Places `Find…` in the Edit menu after the text
/// editing group and binds it to `Command-F`. The command invokes the focused
/// window's `searchFocusAction` (published by `HomeView`); if no window is
/// focused or no action is published, the command is a no-op.
struct SearchCommands: Commands {
    @FocusedValue(\.nextPasteCommandDispatcher) private var dispatcher

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Find…") {
                dispatcher?.send(.focusSearch)
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(dispatcher == nil)
        }
    }
}

/// T007/T009: app-level commands for clearing history. Binds
/// `Option-Command-Delete` (clear unpinned) and `Shift-Option-Command-Delete`
/// (clear all) to the focused window's request-clear actions. These are app menu
/// commands, not global hotkeys. The actual confirmation UI and clearing are owned
/// by `HomeView`.
struct HistoryClearCommands: Commands {
    @FocusedValue(\.nextPasteCommandDispatcher) private var dispatcher

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Divider()
            Button("Clear Unpinned History…") {
                dispatcher?.send(.clearUnpinnedHistory)
            }
            .keyboardShortcut(.delete, modifiers: [.command, .option])
            .disabled(dispatcher == nil)

            Button("Clear All History…") {
                dispatcher?.send(.clearAllHistory)
            }
            .keyboardShortcut(.delete, modifiers: [.command, .option, .shift])
            .disabled(dispatcher == nil)
        }
    }
}
