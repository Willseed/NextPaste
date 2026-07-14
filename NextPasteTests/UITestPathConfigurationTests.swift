//
//  UITestPathConfigurationTests.swift
//  NextPasteTests
//
//  Created by pony on 2026/7/14.
//

import Foundation
import Testing

// Unit-side mirror of the UI-test path configuration contract defined in
// NextPasteUITests/UITestPathConfiguration.swift and UITestAppLauncher.swift.
// Duplicated so the path/key contract can be verified without launching an
// XCUIApplication. Keep this in sync with the UI-test source when it changes.
private enum UITestPathConfigurationContract {
    static let storeURLKey = "NEXTPASTE_UI_TEST_STORE_URL"
    static let dataDirectoryKey = "NEXTPASTE_UI_TEST_DATA_DIRECTORY"
    static let rowActionTraceFileEnvironmentKey = "NEXTPASTE_ROW_ACTION_TRACE_FILE"
    static let uiTestOnDiskStoreArgument = "-ui-test-on-disk-store"
    static let storeFileName = "NextPaste.store"
    static let dataDirectoryName = "ImageStore"
    static let onDiskStoreFolderPrefix = "NextPaste-025-ui-store-"
    static let traceFileNamePrefix = "row-actions-"
    static let traceFileExtension = "jsonl"
}

private struct UITestPathConfiguration: Sendable {
    let artifactRootURL: URL

    init(artifactRootURL: URL) {
        self.artifactRootURL = artifactRootURL.standardizedFileURL
    }

    static var systemDefault: Self {
        #if os(macOS)
        let sharedDirectoryURL = URL(
            fileURLWithPath: NSOpenStepRootDirectory(),
            isDirectory: true
        )
        .appendingPathComponent("Users", isDirectory: true)
        .appendingPathComponent("Shared", isDirectory: true)
        #else
        let sharedDirectoryURL = FileManager.default.temporaryDirectory
        #endif
        return Self(
            artifactRootURL: sharedDirectoryURL
                .appendingPathComponent("NextPasteUITests", isDirectory: true)
        )
    }
}

private struct UITestLaunchEnvironmentPaths: Sendable {
    let identifier: String
    let rootURL: URL
    let storeURL: URL
    let dataDirectoryURL: URL

    init(testName: String, pathConfiguration: UITestPathConfiguration = .systemDefault) {
        let uuid = UUID().uuidString.lowercased()
        let readableName = Self.sanitizedPathComponent(testName)
        let identifier = "\(readableName)-\(uuid)"
        let rootURL = pathConfiguration.artifactRootURL
            .appendingPathComponent(identifier, isDirectory: true)
            .standardizedFileURL
        self.identifier = identifier
        self.rootURL = rootURL
        self.storeURL = rootURL.appendingPathComponent(
            UITestPathConfigurationContract.storeFileName,
            isDirectory: false
        )
        self.dataDirectoryURL = rootURL.appendingPathComponent(
            UITestPathConfigurationContract.dataDirectoryName,
            isDirectory: true
        )
    }

    private static func sanitizedPathComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(String(scalar)) : "-"
        }
        let result = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return result.isEmpty ? "ui-test" : String(result.prefix(80))
    }
}

// Stand-in for XCUIApplication's launch environment and arguments so the
// configure() contract can be asserted without UI-testing infrastructure.
private struct LaunchEnvironmentSink {
    var environment: [String: String] = [:]
    var arguments: [String] = []
}

// Mirrors the subset of UITestLaunchEnvironment.configure(_ app:onDiskStore:)
// and UITestAppLauncher.makeTraceApp that the migrated tests assert against.
private func configure(
    _ sink: inout LaunchEnvironmentSink,
    with environment: UITestLaunchEnvironmentPaths
) {
    sink.arguments.append(contentsOf: [
        UITestPathConfigurationContract.uiTestOnDiskStoreArgument,
        environment.storeURL.path
    ])
    sink.environment[UITestPathConfigurationContract.storeURLKey] = environment.storeURL.path
    sink.environment[UITestPathConfigurationContract.dataDirectoryKey] = environment.dataDirectoryURL.path
}

private func configureTrace(
    _ sink: inout LaunchEnvironmentSink,
    traceURL: URL
) {
    sink.environment[UITestPathConfigurationContract.rowActionTraceFileEnvironmentKey] = traceURL.path
}

private enum UITestOnDiskStorePaths {
    static func rootURL(pathConfiguration: UITestPathConfiguration) -> URL {
        pathConfiguration.artifactRootURL
            .appendingPathComponent(
                "\(UITestPathConfigurationContract.onDiskStoreFolderPrefix)\(UUID().uuidString)",
                isDirectory: true
            )
            .standardizedFileURL
    }

    static func storeURL(rootURL: URL) -> URL {
        rootURL.appendingPathComponent(
            UITestPathConfigurationContract.storeFileName,
            isDirectory: false
        )
    }
}

private enum UITestTracePaths {
    static func traceURL(traceDirectoryURL: URL) -> URL {
        traceDirectoryURL
            .appendingPathComponent(
                "\(UITestPathConfigurationContract.traceFileNamePrefix)\(UUID().uuidString).\(UITestPathConfigurationContract.traceFileExtension)",
                isDirectory: false
            )
            .standardizedFileURL
    }
}

@Suite("UI-test path configuration contract")
struct UITestPathConfigurationTests {
    @Test("default path configuration feeds the active launch environment")
    func defaultPathConfigurationFeedsTheActiveLaunchEnvironment() {
        let configuration = UITestPathConfiguration.systemDefault
        let environment = UITestLaunchEnvironmentPaths(
            testName: "testDefaultPathConfigurationFeedsTheActiveLaunchEnvironment",
            pathConfiguration: configuration
        )

        #expect(environment.rootURL.deletingLastPathComponent() == configuration.artifactRootURL)

        #if os(macOS)
        #expect(
            Array(configuration.artifactRootURL.pathComponents.suffix(3))
                == ["Users", "Shared", "NextPasteUITests"]
        )
        #expect(configuration.artifactRootURL.path.contains(".xctrunner") == false)
        #endif

        var sink = LaunchEnvironmentSink()
        configure(&sink, with: environment)
        #expect(
            sink.environment[UITestPathConfigurationContract.storeURLKey]
                == environment.storeURL.path
        )
        #expect(
            sink.environment[UITestPathConfigurationContract.dataDirectoryKey]
                == environment.dataDirectoryURL.path
        )
        #expect(sink.arguments.contains(environment.storeURL.path))
    }

    @Test("custom path configuration propagates storage and trace URLs")
    func customPathConfigurationPropagatesStorageAndTraceURLs() {
        let customArtifactRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "nextpaste-custom-ui-test-paths-\(UUID().uuidString)",
                isDirectory: true
            )
        let pathConfiguration = UITestPathConfiguration(artifactRootURL: customArtifactRootURL)
        let environment = UITestLaunchEnvironmentPaths(
            testName: "testCustomPathConfigurationPropagatesStorageAndTraceURLs",
            pathConfiguration: pathConfiguration
        )

        var sink = LaunchEnvironmentSink()
        configure(&sink, with: environment)
        #expect(
            sink.environment[UITestPathConfigurationContract.storeURLKey]
                == environment.storeURL.path
        )
        #expect(
            sink.environment[UITestPathConfigurationContract.dataDirectoryKey]
                == environment.dataDirectoryURL.path
        )
        #expect(sink.arguments.contains(environment.storeURL.path))

        let onDiskRootURL = UITestOnDiskStorePaths.rootURL(pathConfiguration: pathConfiguration)
        let onDiskStoreURL = UITestOnDiskStorePaths.storeURL(rootURL: onDiskRootURL)
        #expect(onDiskRootURL.deletingLastPathComponent() == customArtifactRootURL.standardizedFileURL)
        #expect(onDiskStoreURL.lastPathComponent == UITestPathConfigurationContract.storeFileName)

        let traceDirectoryURL = customArtifactRootURL
            .appendingPathComponent("custom-traces", isDirectory: true)
        let traceURL = UITestTracePaths.traceURL(traceDirectoryURL: traceDirectoryURL)
        #expect(traceURL.deletingLastPathComponent() == traceDirectoryURL.standardizedFileURL)
        #expect(traceURL.pathExtension == UITestPathConfigurationContract.traceFileExtension)

        var traceSink = LaunchEnvironmentSink()
        configureTrace(&traceSink, traceURL: traceURL)
        #expect(
            traceSink.environment[UITestPathConfigurationContract.rowActionTraceFileEnvironmentKey]
                == traceURL.path
        )
    }
}