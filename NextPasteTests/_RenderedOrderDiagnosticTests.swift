//
//  _RenderedOrderDiagnosticTests.swift — TEMPORARY diagnostic; delete before finalizing.
//

import Testing
import Foundation
import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
import ApplicationServices
#endif
@testable import NextPaste

#if os(macOS)

@MainActor
struct _RenderedOrderDiagnosticTests {
    @Test("dump hosted accessibility tree")
    func dumpHostedAccessibilityTree() async throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let baseline = Date(timeIntervalSinceReferenceDate: 2_000_000)
        let alphaID = UUID(uuidString: "00000000-0000-0000-0000-0000000000a1")!
        let bravoID = UUID(uuidString: "00000000-0000-0000-0000-0000000000b2")!
        let alpha = ClipItem(id: alphaID, textContent: "alpha", createdAt: baseline)
        let bravo = ClipItem(id: bravoID, textContent: "bravo", createdAt: baseline.addingTimeInterval(1))
        context.insert(alpha)
        context.insert(bravo)
        try context.save()

        let boundary = DeterministicSafeBoundaryAwaiter()
        let view = HomeView()
        view.safeBoundaryAwaiter = boundary
        let hosted = AnyView(view.modelContainer(container))
        let host = NSHostingView(rootView: hosted)
        host.frame = NSRect(x: 0, y: 0, width: 360, height: 320)
        let window = NSWindow(contentRect: NSRect(x: -10_000, y: -10_000, width: 360, height: 320), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        host.layoutSubtreeIfNeeded()

        let targets: Set<String> = ["clip-row-\(alphaID.uuidString)", "clip-row-\(bravoID.uuidString)"]

        let clock = ContinuousClock()
        let start = clock.now
        while view.reconciliationRenderedClipIDs.count != 2 {
            if start.duration(to: clock.now) >= .seconds(3) { break }
            await Task.yield()
            host.layoutSubtreeIfNeeded()
        }

        var dump = ""
        dump += "mirror IDs: \(view.reconciliationRenderedClipIDs)\n"
        dump += "hostingView identifier: \(host.accessibilityIdentifier() ?? "nil")\n"

        func dumpAX(_ el: NSAccessibilityProtocol, _ depth: Int) {
            if depth > 14 { return }
            let id = el.accessibilityIdentifier() ?? "nil"
            let children = (el.accessibilityChildren() ?? []) + (el.accessibilityRows() ?? [])
            dump += String(repeating: "  ", count: depth) + "[\(type(of: el))] id=\(id) children=\(children.count)\n"
            for c in children {
                if let cEl = c as? NSAccessibilityProtocol {
                    dumpAX(cEl, depth + 1)
                }
            }
        }
        dump += "\n=== METHOD A: NSAccessibility children tree ===\n"
        dumpAX(host, 0)
        var aOrder: [String] = []
        func collectA(_ el: NSAccessibilityProtocol, _ depth: Int) {
            if depth > 40 { return }
            if let id = el.accessibilityIdentifier(), targets.contains(id), !aOrder.contains(id) {
                aOrder.append(id); return
            }
            let children = (el.accessibilityChildren() ?? []) + (el.accessibilityRows() ?? [])
            for c in children {
                if let cEl = c as? NSAccessibilityProtocol { collectA(cEl, depth + 1) }
            }
        }
        collectA(host, 0)
        dump += "METHOD A row order: \(aOrder)\n"

        func axChildren(_ el: AXUIElement) -> [AXUIElement] {
            var ref: CFTypeRef?
            AXUIElementCopyAttributeValue(el, kAXChildrenAttribute as CFString, &ref)
            return (ref as? [AXUIElement]) ?? []
        }
        func axID(_ el: AXUIElement) -> String? {
            var ref: CFTypeRef?
            AXUIElementCopyAttributeValue(el, kAXIdentifierAttribute as CFString, &ref)
            return ref as? String
        }
        var bOrder: [String] = []
        func collectB(_ el: AXUIElement, _ depth: Int) {
            if depth > 60 { return }
            if let id = axID(el), targets.contains(id), !bOrder.contains(id) {
                bOrder.append(id)
                return
            }
            for c in axChildren(el) { collectB(c, depth + 1) }
        }
        let appEl = AXUIElementCreateApplication(getpid())
        collectB(appEl, 0)
        dump += "\n=== METHOD B: AXUIElement (pid \(getpid())) ===\n"
        dump += "METHOD B row order: \(bOrder)\n"

        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
        let outURL = cachesDir.appendingPathComponent("rendered-order-dump.txt")
        try dump.write(to: outURL, atomically: true, encoding: .utf8)
        print("DUMP written to \(outURL.path)")
        window.orderOut(nil)
        boundary.releaseAll()
    }
}
#endif