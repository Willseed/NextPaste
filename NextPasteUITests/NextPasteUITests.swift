//
//  NextPasteUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

final class NextPasteUITests: UITestCase {

    @MainActor
    func testDefaultPathConfigurationFeedsTheActiveLaunchEnvironment() throws {
        let environment = try XCTUnwrap(UITestLaunchEnvironmentRegistry.current())
        let expectedEnvironmentRootURL = UITestPathConfiguration.systemDefault.artifactRootURL
        let app = UITestAppLauncher.makeApp()

        XCTAssertEqual(environment.rootURL.deletingLastPathComponent(), expectedEnvironmentRootURL)
        XCTAssertEqual(
            app.launchEnvironment[UITestLaunchEnvironment.storeURLKey],
            environment.storeURL.path
        )
        XCTAssertEqual(
            app.launchEnvironment[UITestLaunchEnvironment.dataDirectoryKey],
            environment.dataDirectoryURL.path
        )
        XCTAssertTrue(app.launchArguments.contains(environment.storeURL.path))
    }

    @MainActor
    func testCustomPathConfigurationPropagatesStorageAndTraceURLs() throws {
        let customArtifactRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nextpaste-custom-ui-test-paths-\(UUID().uuidString)", isDirectory: true)
        let pathConfiguration = UITestPathConfiguration(artifactRootURL: customArtifactRootURL)
        let environment = try UITestLaunchEnvironment(
            testName: name,
            pathConfiguration: pathConfiguration
        )
        defer {
            environment.cleanup()
            try? FileManager.default.removeItem(at: customArtifactRootURL)
        }

        let app = XCUIApplication()
        environment.configure(app, onDiskStore: nil)
        XCTAssertEqual(
            app.launchEnvironment[UITestLaunchEnvironment.storeURLKey],
            environment.storeURL.path
        )
        XCTAssertEqual(
            app.launchEnvironment[UITestLaunchEnvironment.dataDirectoryKey],
            environment.dataDirectoryURL.path
        )
        XCTAssertTrue(app.launchArguments.contains(environment.storeURL.path))

        let store = try UITestAppLauncher.makeOnDiskStore(pathConfiguration: pathConfiguration)
        defer { store.remove() }
        XCTAssertEqual(store.rootURL.deletingLastPathComponent(), customArtifactRootURL.standardizedFileURL)

        let traceDirectoryURL = customArtifactRootURL
            .appendingPathComponent("custom-traces", isDirectory: true)
        let traceLaunch = UITestAppLauncher.makeTraceApp(traceDirectoryURL: traceDirectoryURL)
        XCTAssertEqual(
            traceLaunch.traceURL.deletingLastPathComponent(),
            traceDirectoryURL.standardizedFileURL
        )
        XCTAssertEqual(
            traceLaunch.app.launchEnvironment[UITestAppLauncher.rowActionTraceFileEnvironmentKey],
            traceLaunch.traceURL.path
        )
    }

    @MainActor
    func testIsolatedLaunchExposesReadyMainWindow() throws {
        let app = launchApp()

        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.windows.element(boundBy: 0).exists)
        XCTAssertTrue(app.buttons["new-clip-button"].isEnabled)
    }
}
