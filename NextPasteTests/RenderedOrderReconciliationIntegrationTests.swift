//
//  RenderedOrderReconciliationIntegrationTests.swift
//  NextPasteTests
//
//  Hosted Integration test that verifies the ACTUAL rendered AppKit
//  accessibility tree order before and after a Pin reconciliation, using the
//  stable per-row accessibility IDs assigned by `ClipboardRow`
//  (`clip-row-<UUID>`).
//
//  This is NOT a UI test (no XCUITest / `UITestCase` app launch). It installs a
//  real SwiftUI `HomeView` in an `NSHostingView` inside an off-screen
//  `NSWindow`, drives the real `scheduleTogglePin(_:)` entry point, and reads
//  the published accessibility tree directly through the in-process AppKit
//  `NSAccessibilityProtocol` API.
//
//  It deliberately does NOT prove the UI updated by reading the
//  `reconciliationRenderedClipIDs` / `RowActionDisplayOrderState` mirror. That
//  mirror can only prove the logical projection computed in the SwiftUI body;
//  it cannot prove the SwiftUI List / AppKit accessibility tree has actually
//  published the new order. The assertions below read the accessibility tree
//  itself, so a reconciliation that updates the mirror but never re-publishes
//  the hosted rows would fail here.
//

import Testing
import Foundation
import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
#endif
@testable import NextPaste

#if os(macOS)

// MARK: - Hosted fixture exposing the AppKit accessibility root

/// Self-contained hosted `HomeView` fixture for rendered-order verification.
///
/// It creates its own in-memory `ModelContainer` (independent of the lifecycle
/// suite's shared store), seeds two text clips with deterministic UUIDs, injects
/// the existing deterministic safe-boundary double through the single
/// `HomeView.safeBoundaryAwaiter` seam, and installs the view in a real
/// off-screen `NSWindow` so the SwiftUI body evaluates, `@Query` fetches the
/// clips, and the AppKit accessibility tree publishes the rows. The hosting
/// view is exposed so tests can read the published accessibility tree directly.
@MainActor
final class RenderedOrderHostedFixture {
    let container: ModelContainer
    let context: ModelContext
    let alphaClip: ClipItem
    let bravoClip: ClipItem
    let safeBoundary: DeterministicSafeBoundaryAwaiter
    let homeView: HomeView
    private(set) var hostingView: NSHostingView<AnyView>?
    private(set) var hostWindow: NSWindow?

    /// Deterministic, stable fixture UUIDs so the row accessibility IDs are
    /// reproducible across runs: `clip-row-<alphaID>` / `clip-row-<bravoID>`.
    static let alphaID = UUID(uuidString: "00000000-0000-0000-0000-0000000000a1")!
    static let bravoID = UUID(uuidString: "00000000-0000-0000-0000-0000000000b2")!

    var alphaRowIdentifier: String { "clip-row-\(Self.alphaID.uuidString)" }
    var bravoRowIdentifier: String { "clip-row-\(Self.bravoID.uuidString)" }

    init() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(
            for: Schema([ClipItem.self])
        )
        self.container = container
        let context = ModelContext(container)
        for existing in try context.fetch(FetchDescriptor<ClipItem>()) {
            context.delete(existing)
        }

        let baseline = Date(timeIntervalSinceReferenceDate: 2_000_000)
        let alpha = ClipItem(
            id: Self.alphaID,
            textContent: "rendered-order-alpha",
            createdAt: baseline
        )
        let bravo = ClipItem(
            id: Self.bravoID,
            textContent: "rendered-order-bravo",
            createdAt: baseline.addingTimeInterval(1)
        )
        context.insert(alpha)
        context.insert(bravo)
        try context.save()
        self.context = context
        self.alphaClip = alpha
        self.bravoClip = bravo

        let boundary = DeterministicSafeBoundaryAwaiter()
        let view = HomeView()
        view.safeBoundaryAwaiter = boundary
        self.safeBoundary = boundary
        self.homeView = view

        let hosted = AnyView(view.modelContainer(container))
        let host = NSHostingView(rootView: hosted)
        host.frame = NSRect(x: 0, y: 0, width: 360, height: 320)
        self.hostingView = host

        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 360, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = host
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        self.hostWindow = window
    }

    func layoutIfNeeded() {
        hostingView?.layoutSubtreeIfNeeded()
    }

    func dispose() {
        hostWindow?.orderOut(nil)
        hostWindow?.contentView = nil
        hostingView = nil
        hostWindow = nil
    }
}

// MARK: - Accessibility tree traversal

/// Reads the published AppKit accessibility tree and collects stable row
/// identifiers in their rendered order.
///
/// The traversal is a depth-first pre-order walk over `accessibilityChildren()`
/// (with `accessibilityRows()` as a per-node fallback for `NSTableView`-backed
/// lists that publish rows through the rows attribute). AppKit returns
/// accessibility children in visual order, so the first occurrence of each row
/// identifier reflects its rendered position. Each target identifier is
/// collected at most once, so a row surfaced through both attributes is not
/// double-counted.
@MainActor
enum RenderedAccessibilityOrder {
    static func rowOrder(
        from root: NSAccessibilityProtocol,
        matching identifiers: Set<String>
    ) -> [String] {
        var collected: [String] = []
        traverse(root, matching: identifiers, collected: &collected, depth: 0)
        return collected
    }

    private static func traverse(
        _ element: NSAccessibilityProtocol,
        matching identifiers: Set<String>,
        collected: inout [String],
        depth: Int
    ) {
        if depth > 40 {
            return
        }
        if let identifier = element.accessibilityIdentifier(),
           identifiers.contains(identifier),
           collected.contains(identifier) == false {
            collected.append(identifier)
            return
        }
        let children = (element.accessibilityChildren() ?? [])
            + (element.accessibilityRows() ?? [])
        for child in children {
            guard let childElement = child as? NSAccessibilityProtocol else {
                continue
            }
            traverse(
                childElement,
                matching: identifiers,
                collected: &collected,
                depth: depth + 1
            )
        }
    }
}

// MARK: - Suite

@Suite("Rendered order reconciliation integration", .serialized)
@MainActor
struct RenderedOrderReconciliationIntegrationTests {
    @Test(
        "pin reconciliation reorders the hosted accessibility tree, not just the projection mirror"
    )
    func pinReconciliationReordersHostedAccessibilityTree() async throws {
        let fixture = try RenderedOrderHostedFixture()
        defer { fixture.dispose() }

        let targets: Set<String> = [fixture.alphaRowIdentifier, fixture.bravoRowIdentifier]
        guard let host = fixture.hostingView else {
            Issue.record("The NSHostingView must be installed before asserting rendered order.")
            return
        }

        // Wait for the hosted body to evaluate so @Query fetches both clips and
        // the SwiftUI List publishes its rows into the AppKit accessibility tree.
        // This gate reads the accessibility tree itself, not the projection mirror.
        await ReconciliationLifecycleAssertions.awaitCondition(
            timeout: .seconds(4),
            message: "The hosted body must install and publish both clip rows into the accessibility tree."
        ) { [weak fixture] in
            guard let fixture else { return false }
            fixture.layoutIfNeeded()
            let order = RenderedAccessibilityOrder.rowOrder(
                from: fixture.hostingView ?? host,
                matching: targets
            )
            return Set(order) == targets
        }

        // BEFORE: newest-first ordering places the newer clip (bravo) above the
        // older clip (alpha) in the ACTUAL rendered accessibility tree.
        let beforeOrder = RenderedAccessibilityOrder.rowOrder(
            from: host,
            matching: targets
        )
        #expect(
            beforeOrder == [fixture.bravoRowIdentifier, fixture.alphaRowIdentifier],
            "Before pinning, the rendered accessibility tree must list the newer clip (bravo) above the older clip (alpha). Got: \(beforeOrder)"
        )

        // Drive the REAL Pin entry point on the older clip. The reconciliation
        // snapshot freezes the current projection until the safe boundary
        // releases, so the rendered order must not change yet.
        fixture.homeView.scheduleTogglePin(fixture.alphaClip)

        // Wait for the production reconciliation Task to reach the safe-boundary
        // await (bounded, no fixed sleep).
        await ReconciliationLifecycleAssertions.awaitCondition(
            timeout: .seconds(3),
            message: "The reconciliation Task must reach the safe-boundary await."
        ) { [weak fixture] in
            (fixture?.safeBoundary.pendingWaitCount ?? 0) >= 1
        }

        // WHILE THE SNAPSHOT IS HELD: the rendered accessibility tree must still
        // show the frozen pre-pin order, proving the snapshot holds publication.
        let duringOrder = RenderedAccessibilityOrder.rowOrder(
            from: host,
            matching: targets
        )
        #expect(
            duringOrder == [fixture.bravoRowIdentifier, fixture.alphaRowIdentifier],
            "While the reconciliation snapshot is held, the rendered order must stay frozen at the pre-pin order. Got: \(duringOrder)"
        )

        // Release the safe boundary so the production Task applies the pin,
        // clears the snapshot, and SwiftUI re-publishes the List.
        fixture.safeBoundary.releaseNext()

        // AFTER: the pinned alpha clip must rise above bravo in the ACTUAL
        // accessibility tree. This is the decisive check: it reads the published
        // tree, not the projection mirror, so it fails if SwiftUI never
        // re-publishes the reordered rows.
        await ReconciliationLifecycleAssertions.awaitCondition(
            timeout: .seconds(5),
            message: "After pinning alpha, the rendered accessibility tree must publish alpha above bravo."
        ) { [weak fixture] in
            guard let fixture, let host = fixture.hostingView else { return false }
            fixture.layoutIfNeeded()
            let order = RenderedAccessibilityOrder.rowOrder(from: host, matching: targets)
            return order == [fixture.alphaRowIdentifier, fixture.bravoRowIdentifier]
        }

        let afterOrder = RenderedAccessibilityOrder.rowOrder(
            from: host,
            matching: targets
        )
        #expect(
            afterOrder == [fixture.alphaRowIdentifier, fixture.bravoRowIdentifier],
            "After pinning alpha, the rendered accessibility tree must list alpha (pinned) above bravo. Got: \(afterOrder)"
        )

        // Drain any remaining waiter so no safe-boundary continuation leaks.
        fixture.safeBoundary.releaseAll()
    }
}

#endif