//
//  DebugUITestLaunchEnvironment.swift
//  NextPaste
//

import Foundation
#if DEBUG
import Combine
#endif
#if os(macOS)
import AppKit
import SwiftUI
#endif

#if DEBUG
/// Debug-only configuration supplied by the UI-test runner. A complete set of
/// values is required so an accidental `-ui-testing` launch cannot redirect a
/// subset of production state.
nonisolated struct DebugUITestLaunchEnvironment: Sendable {
    static let identifierKey = "NEXTPASTE_UI_TEST_ID"
    static let defaultsSuiteKey = "NEXTPASTE_UI_TEST_DEFAULTS_SUITE"
    static let storeURLKey = "NEXTPASTE_UI_TEST_STORE_URL"
    static let dataDirectoryKey = "NEXTPASTE_UI_TEST_DATA_DIRECTORY"
    static let pasteboardNameKey = "NEXTPASTE_UI_TEST_PASTEBOARD_NAME"
    static let ocrScenarioKey = "NEXTPASTE_UI_TEST_OCR_SCENARIO"
    static let ocrTextKey = "NEXTPASTE_UI_TEST_OCR_TEXT"
    static let initialLanguageKey = "NEXTPASTE_UI_TEST_INITIAL_LANGUAGE"
    static let launchStartedUptimeKey = "NEXTPASTE_UI_TEST_LAUNCH_STARTED_UPTIME"
    static let expectedHistoryCountKey = "NEXTPASTE_UI_TEST_EXPECTED_HISTORY_COUNT"
    static let colorSchemeContrastKey = "NEXTPASTE_UI_TEST_COLOR_SCHEME_CONTRAST"
    static let reduceTransparencyKey = "NEXTPASTE_UI_TEST_REDUCE_TRANSPARENCY"

    let identifier: String
    let defaultsSuiteName: String
    let storeURL: URL
    let dataDirectoryURL: URL
    let pasteboardName: String
    let ocrFixture: DebugUITestOCRFixture?
    let initialLanguageRawValue: String?
    let forceIncreasedColorContrast: Bool?
    let forceReduceTransparency: Bool?
    let launchReadinessConfiguration: DebugUITestLaunchReadinessConfiguration?

    init?(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        guard arguments.contains("-ui-testing"),
              let identifier = Self.nonemptyValue(for: Self.identifierKey, in: environment),
              let defaultsSuiteName = Self.nonemptyValue(for: Self.defaultsSuiteKey, in: environment),
              let storePath = Self.nonemptyValue(for: Self.storeURLKey, in: environment),
              let dataDirectoryPath = Self.nonemptyValue(for: Self.dataDirectoryKey, in: environment),
              let pasteboardName = Self.nonemptyValue(for: Self.pasteboardNameKey, in: environment) else {
            return nil
        }

        self.identifier = identifier
        self.defaultsSuiteName = defaultsSuiteName
        self.storeURL = URL(fileURLWithPath: storePath).standardizedFileURL
        self.dataDirectoryURL = URL(fileURLWithPath: dataDirectoryPath, isDirectory: true).standardizedFileURL
        self.pasteboardName = pasteboardName

        if let rawScenario = environment[Self.ocrScenarioKey] {
            guard let scenario = DebugUITestOCRScenario(rawValue: rawScenario) else {
                return nil
            }
            let text = environment[Self.ocrTextKey]
            if scenario.requiresText,
               text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                return nil
            }
            self.ocrFixture = DebugUITestOCRFixture(scenario: scenario, text: text)
        } else {
            self.ocrFixture = nil
        }

        if let rawLanguage = environment[Self.initialLanguageKey] {
            guard AppLanguage(rawValue: rawLanguage) != nil else { return nil }
            self.initialLanguageRawValue = rawLanguage
        } else {
            self.initialLanguageRawValue = nil
        }

        let rawLaunchStartedUptime = environment[Self.launchStartedUptimeKey]
        let rawExpectedHistoryCount = environment[Self.expectedHistoryCountKey]
        let rawColorSchemeContrast = environment[Self.colorSchemeContrastKey]
        let rawReduceTransparency = environment[Self.reduceTransparencyKey]
        switch (rawLaunchStartedUptime, rawExpectedHistoryCount) {
        case (nil, nil):
            self.launchReadinessConfiguration = nil
        case let (rawUptime?, rawCount?):
            guard let uptime = TimeInterval(rawUptime),
                  uptime.isFinite,
                  uptime >= 0,
                  let expectedCount = Int(rawCount),
                  expectedCount >= 0 else {
                return nil
            }
            self.launchReadinessConfiguration = DebugUITestLaunchReadinessConfiguration(
                launchStartedUptime: uptime,
                expectedHistoryCount: expectedCount
            )
        default:
            return nil
        }
        forceIncreasedColorContrast = Self.boolValue(for: rawColorSchemeContrast)
        forceReduceTransparency = Self.boolValue(for: rawReduceTransparency)
    }

    var defaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: defaultsSuiteName) else {
            preconditionFailure("Unable to create isolated UI-test defaults suite")
        }
        return defaults
    }

    private static func nonemptyValue(
        for key: String,
        in environment: [String: String]
    ) -> String? {
        guard let value = environment[key], value.isEmpty == false else {
            return nil
        }
        return value
    }

    private static func boolValue(for rawValue: String?) -> Bool? {
        guard let rawValue else { return nil }
        switch rawValue.lowercased() {
        case "1", "true", "yes", "on":
            return true
        case "0", "false", "no", "off":
            return false
        default:
            return nil
        }
    }
}

nonisolated struct DebugUITestLaunchReadinessConfiguration: Equatable, Sendable {
    let launchStartedUptime: TimeInterval
    let expectedHistoryCount: Int
}

/// Content-free, Debug-only launch metric. The first authoritative projection
/// with the expected item count freezes only after both the main toolbar and
/// history viewport have completed a non-empty layout. Later renders or
/// mutations cannot make a slow launch look faster.
nonisolated struct DebugUITestLaunchReadinessProbe: Equatable, Sendable {
    private(set) var elapsed: TimeInterval?

    mutating func observe(
        authoritativeHistoryCount: Int,
        mainToolbarLaidOut: Bool,
        historyViewportLaidOut: Bool,
        nowUptime: TimeInterval,
        configuration: DebugUITestLaunchReadinessConfiguration?
    ) {
        guard elapsed == nil,
              let configuration,
              authoritativeHistoryCount == configuration.expectedHistoryCount,
              mainToolbarLaidOut,
              historyViewportLaidOut,
              nowUptime.isFinite,
              nowUptime >= configuration.launchStartedUptime else {
            return
        }
        elapsed = nowUptime - configuration.launchStartedUptime
    }
}

nonisolated enum DebugUITestOCRScenario: String, Sendable {
    case success
    case noText
    case failure
    case suspended

    var requiresText: Bool {
        self == .success || self == .suspended
    }
}

nonisolated struct DebugUITestOCRFixture: Sendable {
    let scenario: DebugUITestOCRScenario
    let text: String?
}

private enum DebugUITestOCRError: Error {
    case deterministicFailure
}

/// Replaces only Vision's nondeterministic recognition boundary. The app still
/// executes its real context-menu action, coordinator state machine, current-
/// item validation, normalization, and pasteboard command.
actor DebugUITestImageTextRecognizer: ImageTextRecognizing {
    private let fixture: DebugUITestOCRFixture
    private var suspendedContinuation: CheckedContinuation<Void, Error>?
    private var completionRequested = false

    init(fixture: DebugUITestOCRFixture) {
        self.fixture = fixture
    }

    func recognizeText(in _: URL) async throws -> String? {
        switch fixture.scenario {
        case .success:
            return fixture.text
        case .noText:
            return nil
        case .failure:
            throw DebugUITestOCRError.deterministicFailure
        case .suspended:
            try await waitForControlledCompletion()
            return fixture.text
        }
    }

    func completeSuspendedRecognition() {
        guard let suspendedContinuation else {
            completionRequested = true
            return
        }
        self.suspendedContinuation = nil
        suspendedContinuation.resume()
    }

    private func waitForControlledCompletion() async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if completionRequested {
                    completionRequested = false
                    continuation.resume()
                } else {
                    suspendedContinuation = continuation
                }
            }
        } onCancel: {
            Task { await self.cancelSuspendedRecognition() }
        }
    }

    private func cancelSuspendedRecognition() {
        suspendedContinuation?.resume(throwing: CancellationError())
        suspendedContinuation = nil
        completionRequested = false
    }
}
#endif

#if os(macOS)
/// The product always uses the general pasteboard outside a complete Debug
/// UI-test launch environment.
nonisolated enum AppPasteboard {
    static var current: NSPasteboard {
#if DEBUG
        if let name = DebugUITestLaunchEnvironment()?.pasteboardName {
            return NSPasteboard(name: NSPasteboard.Name(name))
        }
#endif
        return .general
    }
}
#endif

#if DEBUG && os(macOS)
@MainActor
final class DebugUITestApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard DebugUITestLaunchEnvironment() != nil,
              let application = notification.object as? NSApplication else {
            return
        }

        application.activate(ignoringOtherApps: true)

        if let window = application.windows.first {
            window.makeKeyAndOrderFront(nil)
            return
        }

        guard let newWindowItem = Self.newWindowMenuItem(in: application.mainMenu),
              let action = newWindowItem.action else {
            preconditionFailure("SwiftUI did not install the public New Window command for UI testing")
        }

        precondition(
            application.sendAction(action, to: newWindowItem.target, from: newWindowItem),
            "SwiftUI's public New Window command did not create the UI-test window"
        )
    }

    private static func newWindowMenuItem(in mainMenu: NSMenu?) -> NSMenuItem? {
        mainMenu?.items
            .compactMap(\.submenu)
            .flatMap(\.items)
            .first { item in
                item.keyEquivalent.lowercased() == "n"
                    && item.keyEquivalentModifierMask.contains(.command)
                    && item.isEnabled
                    && item.action != nil
            }
    }
}

/// Binds activation to the actual SwiftUI window entering AppKit's hierarchy.
/// This avoids timing assumptions and makes the window key before XCUITest
/// starts querying accessibility state.
struct UITestWindowActivationView: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView {
        ActivationView()
    }

    func updateNSView(_: NSView, context _: Context) {
        // Activation is tied to `viewDidMoveToWindow`; this representable has
        // no mutable input whose later SwiftUI updates should reactivate or
        // reorder the already-installed window.
    }

    private final class ActivationView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            guard let window else { return }
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct UITestOCRCompletionControl: View {
    let recognizer: DebugUITestImageTextRecognizer

    var body: some View {
        Button {
            Task { await recognizer.completeSuspendedRecognition() }
        } label: {
            Text("Complete suspended OCR")
                .frame(width: 18, height: 18)
                .opacity(0.01)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ui-test-complete-suspended-ocr")
        .accessibilityLabel("Complete suspended OCR")
    }
}

struct DebugUITestAccessibilityProbe: View {
    let identifier: String
    let label: String
    let value: String

    var body: some View {
        Text(label)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(label)
            .accessibilityValue(value)
    }
}

/// Read-only visibility into the real AppKit application appearance used by
/// deterministic UI assertions. Production behavior is never routed through
/// this probe.
@MainActor
enum DebugUITestApplicationAppearanceState {
    static var overrideValue: String {
        guard let appearance = NSApplication.shared.appearance else {
            return "system"
        }
        return effectiveValue(for: appearance)
    }

    static var effectiveValue: String {
        effectiveValue(for: NSApplication.shared.effectiveAppearance)
    }

    private static func effectiveValue(for appearance: NSAppearance) -> String {
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? "dark" : "light"
    }
}

/// Content-free observation of the real clipboard monitor poll path. UI tests
/// use this only to prove that an ignored payload was actually consumed before
/// writing the next fixture; clipboard text and image metadata are never kept.
@MainActor
final class DebugUITestClipboardMonitorProbe: ObservableObject {
    static let shared = DebugUITestClipboardMonitorProbe()

    @Published private(set) var isMonitoring = false
    @Published private(set) var observationCount = 0
    @Published private(set) var lastDisposition = "none"

    private init() {
        // The shared probe is the single process-wide observation stream; a
        // private initializer prevents additional instances from splitting
        // clipboard-monitor events across independent counters.
    }

    func recordMonitoringStarted() {
        isMonitoring = true
    }

    func recordMonitoringStopped() {
        isMonitoring = false
    }

    func record(_ outcome: ClipboardCaptureService.CaptureOutcome) {
        observationCount += 1
        switch outcome {
        case .captured:
            lastDisposition = "captured"
        case .ignored(.duplicate):
            lastDisposition = "ignored-duplicate"
        case .ignored(.emptyOrWhitespace):
            lastDisposition = "ignored-empty-or-whitespace"
        case .ignored(.nonText):
            lastDisposition = "ignored-non-text"
        case .failed:
            lastDisposition = "failed"
        }
    }
}
#endif
