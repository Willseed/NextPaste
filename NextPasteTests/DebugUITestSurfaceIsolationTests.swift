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
    func completeDebugUITestEnvironmentEnablesLaunchArgumentSeams() throws {
        let monitor = ClipboardMonitorConfiguration(
            arguments: Self.simulationArguments,
            environment: Self.completeEnvironment
        )

#if DEBUG
        let debugEnvironment = try #require(
            DebugUITestLaunchEnvironment(
                arguments: Self.simulationArguments,
                environment: Self.completeEnvironment
            )
        )
        #expect(monitor.isEnabled == false)
        #expect(monitor.pollInterval == 0.125)
#if os(iOS)
        let namespace = try #require(
            Self.completeEnvironment[DebugUITestLaunchEnvironment.storageNamespaceKey]
        )
        let applicationSupportDirectory = try #require(
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        )
        let expectedPaths = try #require(
            DebugUITestLaunchEnvironment.appContainerStoragePaths(
                namespace: namespace,
                applicationSupportDirectory: applicationSupportDirectory
            )
        )
        #expect(debugEnvironment.storeURL == expectedPaths.storeURL)
        #expect(debugEnvironment.dataDirectoryURL == expectedPaths.dataDirectoryURL)
#else
        let defaultStorageFixture = LaunchStorageFixture()
        #expect(debugEnvironment.storeURL == defaultStorageFixture.storeURL)
        #expect(debugEnvironment.dataDirectoryURL == defaultStorageFixture.dataDirectoryURL)
#endif
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

#if DEBUG
    @Test("logical iOS storage namespace resolves only inside the app container")
    func logicalIOSStorageNamespaceResolvesInsideAppContainer() throws {
        let appContainerRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("NextPaste-simulated-app-container", isDirectory: true)
        let namespace = "5dc97e97-474a-4b86-8418-d0a843d99035"
        let paths = try #require(
            DebugUITestLaunchEnvironment.appContainerStoragePaths(
                namespace: namespace,
                applicationSupportDirectory: appContainerRoot
            )
        )

        let expectedRoot = appContainerRoot
            .appendingPathComponent("NextPasteUITests", isDirectory: true)
            .appendingPathComponent(namespace, isDirectory: true)
            .standardizedFileURL
        #expect(paths.rootURL == expectedRoot)
        #expect(paths.storeURL == expectedRoot.appendingPathComponent("NextPaste.store"))
        #expect(
            paths.dataDirectoryURL
                == expectedRoot.appendingPathComponent("ImageStore", isDirectory: true)
        )
        #expect(
            DebugUITestLaunchEnvironment.appContainerStoragePaths(
                namespace: "../outside-container",
                applicationSupportDirectory: appContainerRoot
            ) == nil
        )
    }

#if os(iOS)
    @Test("iOS Debug UI-test environment requires a logical storage namespace")
    func iosDebugEnvironmentRequiresLogicalStorageNamespace() throws {
        let environment = Self.completeEnvironment
        let configuration = try #require(
            DebugUITestLaunchEnvironment(
                arguments: Self.simulationArguments,
                environment: environment
            )
        )

        #expect(environment[DebugUITestLaunchEnvironment.storageNamespaceKey] != nil)
        #expect(environment[DebugUITestLaunchEnvironment.storeURLKey] == nil)
        #expect(environment[DebugUITestLaunchEnvironment.dataDirectoryKey] == nil)
        #expect(configuration.storeURL.lastPathComponent == "NextPaste.store")
        #expect(configuration.dataDirectoryURL.lastPathComponent == "ImageStore")

        var missingNamespace = environment
        missingNamespace.removeValue(forKey: DebugUITestLaunchEnvironment.storageNamespaceKey)
        #expect(
            DebugUITestLaunchEnvironment(
                arguments: Self.simulationArguments,
                environment: missingNamespace
            ) == nil
        )

        var malformedNamespace = environment
        malformedNamespace[DebugUITestLaunchEnvironment.storageNamespaceKey] = "not-a-uuid"
        #expect(
            DebugUITestLaunchEnvironment(
                arguments: Self.simulationArguments,
                environment: malformedNamespace
            ) == nil
        )
    }
#endif

    @Test("launch readiness configuration requires a complete valid pair")
    func launchReadinessConfigurationRequiresACompleteValidPair() {
        var validEnvironment = Self.completeEnvironment
        validEnvironment[DebugUITestLaunchEnvironment.launchStartedUptimeKey] = "120.5"
        validEnvironment[DebugUITestLaunchEnvironment.expectedHistoryCountKey] = "500"

        let valid = DebugUITestLaunchEnvironment(
            arguments: Self.simulationArguments,
            environment: validEnvironment
        )
        #expect(
            valid?.launchReadinessConfiguration
                == DebugUITestLaunchReadinessConfiguration(
                    launchStartedUptime: 120.5,
                    expectedHistoryCount: 500
                )
        )

        var missingCount = validEnvironment
        missingCount.removeValue(forKey: DebugUITestLaunchEnvironment.expectedHistoryCountKey)
        #expect(
            DebugUITestLaunchEnvironment(
                arguments: Self.simulationArguments,
                environment: missingCount
            ) == nil
        )

        var malformedUptime = validEnvironment
        malformedUptime[DebugUITestLaunchEnvironment.launchStartedUptimeKey] = "not-a-number"
        #expect(
            DebugUITestLaunchEnvironment(
                arguments: Self.simulationArguments,
                environment: malformedUptime
            ) == nil
        )
    }

    @Test("launch readiness freezes only after exact projection and completed layout")
    func launchReadinessFreezesOnlyTheFirstExactAuthoritativeProjection() {
        let configuration = DebugUITestLaunchReadinessConfiguration(
            launchStartedUptime: 100,
            expectedHistoryCount: 500
        )
        var probe = DebugUITestLaunchReadinessProbe()

        probe.observe(
            authoritativeHistoryCount: 499,
            mainToolbarLaidOut: true,
            historyViewportLaidOut: true,
            nowUptime: 101,
            configuration: configuration
        )
        #expect(probe.elapsed == nil)

        probe.observe(
            authoritativeHistoryCount: 500,
            mainToolbarLaidOut: true,
            historyViewportLaidOut: true,
            nowUptime: 99,
            configuration: configuration
        )
        #expect(probe.elapsed == nil)

        probe.observe(
            authoritativeHistoryCount: 500,
            mainToolbarLaidOut: true,
            historyViewportLaidOut: false,
            nowUptime: 101,
            configuration: configuration
        )
        #expect(probe.elapsed == nil)

        probe.observe(
            authoritativeHistoryCount: 500,
            mainToolbarLaidOut: false,
            historyViewportLaidOut: true,
            nowUptime: 101,
            configuration: configuration
        )
        #expect(probe.elapsed == nil)

        probe.observe(
            authoritativeHistoryCount: 500,
            mainToolbarLaidOut: true,
            historyViewportLaidOut: true,
            nowUptime: 101.25,
            configuration: configuration
        )
        #expect(probe.elapsed == 1.25)

        probe.observe(
            authoritativeHistoryCount: 500,
            mainToolbarLaidOut: true,
            historyViewportLaidOut: true,
            nowUptime: 102.5,
            configuration: configuration
        )
        #expect(probe.elapsed == 1.25)
    }

    @Test("launch readiness is emitted only by count-coupled layout preferences")
    func launchReadinessIsEmittedOnlyByCountCoupledLayoutPreferences() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let homeViewURL = repositoryRoot
            .appendingPathComponent("NextPaste", isDirectory: true)
            .appendingPathComponent("HomeView.swift", isDirectory: false)
        let homeViewSource = try String(
            contentsOf: homeViewURL,
            encoding: .utf8
        )

        #expect(homeViewSource.contains(".onPreferenceChange(DebugUITestLaunchLayoutPreferenceKey.self)"))
        #expect(homeViewSource.contains("authoritativeHistoryCount: visibleClips.count"))
        #expect(homeViewSource.contains("authoritativeHistoryCount: rows.count"))
        #expect(
            homeViewSource.components(
                separatedBy: "recordUITestLaunchReadinessIfNeeded("
            ).count - 1 == 2,
            "Only the layout preference callback and function declaration may reference the readiness recorder"
        )
    }

#if os(macOS)
    @Test("custom UI-test storage URLs propagate through the Debug launch environment")
    func customStorageURLsPropagateThroughDebugLaunchEnvironment() throws {
        let customRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("custom-surface-isolation", isDirectory: true)
        let storageFixture = LaunchStorageFixture(rootDirectoryURL: customRootURL)
        let environment = Self.makeCompleteEnvironment(storageFixture: storageFixture)
        let configuration = try #require(
            DebugUITestLaunchEnvironment(
                arguments: Self.simulationArguments,
                environment: environment
            )
        )

        #expect(configuration.storeURL == storageFixture.storeURL)
        #expect(configuration.dataDirectoryURL == storageFixture.dataDirectoryURL)
        #expect(environment[DebugUITestLaunchEnvironment.storeURLKey] == storageFixture.storeURL.path)
        #expect(
            environment[DebugUITestLaunchEnvironment.dataDirectoryKey]
                == storageFixture.dataDirectoryURL.path
        )
    }
#endif
#endif

    private static let simulationArguments = [
        "-ui-testing",
        UITestArgument.disableClipboardMonitor,
        UITestArgument.clipboardMonitorPollInterval,
        "0.125",
        ClipboardWriter.simulatedFailureArgument,
        NewClipView.simulatedSaveFailureArgument
    ]

    private static let completeEnvironment = makeCompleteEnvironment()

    private static func makeCompleteEnvironment(
        storageFixture: LaunchStorageFixture = LaunchStorageFixture()
    ) -> [String: String] {
#if os(iOS)
        [
            DebugUITestLaunchEnvironment.identifierKey: "surface-isolation",
            DebugUITestLaunchEnvironment.defaultsSuiteKey: "pylot.NextPaste.Tests.surface-isolation",
            DebugUITestLaunchEnvironment.storageNamespaceKey: "d17077a1-a752-4bed-bb5d-53f9c664e53a",
            DebugUITestLaunchEnvironment.pasteboardNameKey: "pylot.NextPaste.Tests.surface-isolation.pasteboard"
        ]
#else
        [
            DebugUITestLaunchEnvironment.identifierKey: "surface-isolation",
            DebugUITestLaunchEnvironment.defaultsSuiteKey: "pylot.NextPaste.Tests.surface-isolation",
            DebugUITestLaunchEnvironment.storeURLKey: storageFixture.storeURL.path,
            DebugUITestLaunchEnvironment.dataDirectoryKey: storageFixture.dataDirectoryURL.path,
            DebugUITestLaunchEnvironment.pasteboardNameKey: "pylot.NextPaste.Tests.surface-isolation.pasteboard"
        ]
#endif
    }

    private static let incompleteEnvironments: [[String: String]] = {
        var environments: [[String: String]] = [[:]]
        for key in completeEnvironment.keys {
            var environment = completeEnvironment
            environment.removeValue(forKey: key)
            environments.append(environment)
        }
        return environments
    }()

    private struct LaunchStorageFixture {
        let storeURL: URL
        let dataDirectoryURL: URL

        init(rootDirectoryURL: URL = FileManager.default.temporaryDirectory) {
            storeURL = rootDirectoryURL
                .appendingPathComponent("NextPaste-surface-isolation.store", isDirectory: false)
                .standardizedFileURL
            dataDirectoryURL = rootDirectoryURL
                .appendingPathComponent("NextPaste-surface-isolation-images", isDirectory: true)
                .standardizedFileURL
        }
    }
}
