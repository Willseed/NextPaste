//
//  DebugUITestSurfaceIsolationTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@Suite("Debug UI-test surface isolation")
struct DebugUITestSurfaceIsolationTests {
    @Test("launch-argument seams ignore an incomplete UI-test environment")
    func launchArgumentSeamsIgnoreIncompleteEnvironment() {
        let arguments = Self.simulationArguments

        for environment in Self.incompleteEnvironments {
            let monitor = ClipboardMonitorConfiguration(
                arguments: arguments,
                environment: environment
            )

            #expect(monitor.isEnabled)
            #expect(monitor.pollInterval == ClipboardMonitorConfiguration.defaultPollInterval)
            #expect(
                ClipboardWriter.shouldSimulateFailureForApplicationLaunch(
                    arguments: arguments,
                    environment: environment
                ) == false
            )
            #expect(
                NewClipView.shouldSimulateSaveFailureForApplicationLaunch(
                    arguments: arguments,
                    environment: environment
                ) == false
            )
        }
    }

    @Test("complete Debug UI-test environment enables its launch-argument seams")
    func completeDebugUITestEnvironmentEnablesLaunchArgumentSeams() {
        let monitor = ClipboardMonitorConfiguration(
            arguments: Self.simulationArguments,
            environment: Self.completeEnvironment
        )

#if DEBUG
        #expect(monitor.isEnabled == false)
        #expect(monitor.pollInterval == 0.125)
        #expect(
            ClipboardWriter.shouldSimulateFailureForApplicationLaunch(
                arguments: Self.simulationArguments,
                environment: Self.completeEnvironment
            )
        )
        #expect(
            NewClipView.shouldSimulateSaveFailureForApplicationLaunch(
                arguments: Self.simulationArguments,
                environment: Self.completeEnvironment
            )
        )
#else
        #expect(monitor.isEnabled)
        #expect(monitor.pollInterval == ClipboardMonitorConfiguration.defaultPollInterval)
        #expect(
            ClipboardWriter.shouldSimulateFailureForApplicationLaunch(
                arguments: Self.simulationArguments,
                environment: Self.completeEnvironment
            ) == false
        )
        #expect(
            NewClipView.shouldSimulateSaveFailureForApplicationLaunch(
                arguments: Self.simulationArguments,
                environment: Self.completeEnvironment
            ) == false
        )
#endif
    }

    @Test("explicit injection seams remain independent of app launch arguments")
    func explicitInjectionSeamsRemainAvailable() {
        let monitor = ClipboardMonitorConfiguration(isEnabled: false, pollInterval: 0.25)

        #expect(monitor.isEnabled == false)
        #expect(monitor.pollInterval == 0.25)
        _ = NewClipView(simulateSaveFailure: true)
    }

    private static let simulationArguments = [
        "-ui-testing",
        UITestArgument.disableClipboardMonitor,
        UITestArgument.clipboardMonitorPollInterval,
        "0.125",
        ClipboardWriter.simulatedFailureArgument,
        NewClipView.simulatedSaveFailureArgument
    ]

    private static let completeEnvironment = [
        "NEXTPASTE_UI_TEST_ID": "surface-isolation",
        "NEXTPASTE_UI_TEST_DEFAULTS_SUITE": "pylot.NextPaste.Tests.surface-isolation",
        "NEXTPASTE_UI_TEST_STORE_URL": "/tmp/NextPaste-surface-isolation.store",
        "NEXTPASTE_UI_TEST_DATA_DIRECTORY": "/tmp/NextPaste-surface-isolation-images",
        "NEXTPASTE_UI_TEST_PASTEBOARD_NAME": "pylot.NextPaste.Tests.surface-isolation.pasteboard"
    ]

    private static let incompleteEnvironments: [[String: String]] = {
        var environments: [[String: String]] = [[:]]
        for key in completeEnvironment.keys {
            var environment = completeEnvironment
            environment.removeValue(forKey: key)
            environments.append(environment)
        }
        return environments
    }()
}
