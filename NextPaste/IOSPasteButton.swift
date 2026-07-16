#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

/// A visible system paste control is the only iOS cross-App clipboard import
/// boundary. Its callback providers are passed directly to the shared decoder;
/// this view never reads the general pasteboard itself.
struct IOSPasteButton: View {
    enum Presentation {
        case prominent
        case toolbar
    }

    @EnvironmentObject private var coordinator: IOSClipboardImportCoordinator
    let presentation: Presentation

    init(presentation: Presentation = .prominent) {
        self.presentation = presentation
    }

    @ViewBuilder
    var body: some View {
        switch presentation {
        case .prominent:
            pasteControl
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(minHeight: 44)
        case .toolbar:
            pasteControl
        }
    }

    private var pasteControl: some View {
        PasteButton(
            supportedContentTypes: [.image, .plainText]
        ) { itemProviders in
            coordinator.importUserProvided(itemProviders: itemProviders)
        }
        .accessibilityIdentifier("ios-paste-button")
        .accessibilityLabel(Text("Paste from Clipboard"))
        .accessibilityHint(Text("Paste the current text or image into NextPaste"))
    }
}
#endif
