import Foundation
import Testing
@testable import NextPaste

@Suite("Focused scene command dispatcher")
@MainActor
struct FocusedSceneCommandDispatcherTests {
    @Test("stable dispatcher forwards commands to the current owner")
    func forwardsToCurrentOwner() {
        let dispatcher = FocusedSceneCommandDispatcher()
        var received: [FocusedSceneCommandDispatcher.Request] = []
        _ = dispatcher.install { received.append($0) }

        dispatcher.send(.focusSearch)
        dispatcher.send(.clearUnpinnedHistory)
        dispatcher.send(.clearAllHistory)

        #expect(received == [.focusSearch, .clearUnpinnedHistory, .clearAllHistory])
    }

    @Test("an old generation cannot clear the current command owner")
    func staleOwnerCannotClearCurrentHandler() {
        let dispatcher = FocusedSceneCommandDispatcher()
        var firstOwnerCount = 0
        var currentOwnerCount = 0
        let staleGeneration = dispatcher.install { _ in firstOwnerCount += 1 }
        let currentGeneration = dispatcher.install { _ in currentOwnerCount += 1 }

        dispatcher.uninstall(owner: staleGeneration)
        dispatcher.send(.focusSearch)

        #expect(firstOwnerCount == 0)
        #expect(currentOwnerCount == 1)

        dispatcher.uninstall(owner: currentGeneration)
        dispatcher.send(.focusSearch)
        #expect(currentOwnerCount == 1)
    }
}
