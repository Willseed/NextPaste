//
//  WindowAccessibilityHostBridge.swift
//  NextPaste
//
//  Applies a useful label to the AppKit content-view accessibility group that
//  hosts a SwiftUI scene. SwiftUI view modifiers label the rendered subtree,
//  while AppKit exposes the hosting content view as a separate AX group.
//

#if os(macOS)
import AppKit
import SwiftUI

struct WindowAccessibilityHostBridge: NSViewRepresentable {
    let label: String
    let identifier: String

    func makeNSView(context _: Context) -> ResolverView {
        let view = ResolverView(frame: .zero)
        view.resolvedLabel = label
        view.resolvedIdentifier = identifier
        return view
    }

    func updateNSView(_ nsView: ResolverView, context _: Context) {
        nsView.resolvedLabel = label
        nsView.resolvedIdentifier = identifier
        nsView.updateHostAccessibility()
    }

    final class ResolverView: NSView {
        var resolvedLabel = ""
        var resolvedIdentifier = ""

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateHostAccessibility()
        }

        func updateHostAccessibility() {
            guard resolvedLabel.isEmpty == false,
                  resolvedIdentifier.isEmpty == false,
                  let contentView = window?.contentView else {
                return
            }
            contentView.setAccessibilityLabel(resolvedLabel)
            contentView.setAccessibilityIdentifier(resolvedIdentifier)
        }
    }
}
#endif
