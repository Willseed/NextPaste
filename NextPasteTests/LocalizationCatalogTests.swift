//
//  LocalizationCatalogTests.swift
//  NextPasteTests
//
//  T026 — verify the string catalog covers the branch-owned user-facing strings
//  and that every project-supported locale has a translated value.
//

import Foundation
import Testing
@testable import NextPaste

struct LocalizationCatalogTests {
    private let featureBilingualKeys: Set<String> = [
        "1–1000",
        "A clipboard manager for Apple platforms.",
        "A single key without modifiers cannot be a shortcut.",
        "About",
        "About NextPaste",
        "All Clips",
        "Appearance",
        "App Language",
        "At least one modifier is required.",
        "Complete suspended OCR",
        "Cancel Recording",
        "Changes apply immediately throughout NextPaste.",
        "Choose a different filter.",
        "Clear All History",
        "Clear Shortcut",
        "Clear Unpinned History",
        "Clips",
        "Close",
        "Command",
        "Command-, is used for Settings.",
        "Command-F is used for search.",
        "Control",
        "Copy",
        "Copy Image Text",
        "Copy Original Image",
        "Current global shortcut",
        "Dark",
        "Data & Privacy",
        "Delete",
        "Disable the global keyboard shortcut",
        "English (United States)",
        "Escape",
        "Filter",
        "Filter Clipboard History",
        "Find…",
        "Follow System",
        "General",
        "Global Shortcut",
        "History",
        "History limit could not be applied. Try again.",
        "Image Text Recognition Failed",
        "Image Clips",
        "Keep up to %lld unpinned clipboard items. Pinned items are always kept.",
        "Language",
        "Light",
        "Minimize",
        "New Clip",
        "NextPaste keeps your clipboard history on this Mac. Content is stored locally and is never sent to a server.",
        "No clips match this filter",
        "No Text Found in Image",
        "None",
        "Option",
        "Option alone cannot be a shortcut.",
        "Permanently remove clipboard history. Pinned items are preserved when clearing unpinned history only.",
        "Pin",
        "Pinned",
        "Pinned Clips",
        "Press a key combination…",
        "Quit",
        "Record Shortcut",
        "Record a new global keyboard shortcut",
        "Recognizing Image Text",
        "Recognizing Image Text…",
        "Reset to Default",
        "Restore the default global keyboard shortcut",
        "Return",
        "Retry Copy Image Text",
        "Settings",
        "Shift",
        "Shortcut is already in use.",
        "Shortcuts",
        "Space",
        "Storage Limit",
        "Storage Limit Range",
        "Storage Limit Value",
        "Tab",
        "Text Clips",
        "This shortcut conflicts with the %@ menu command.",
        "Traditional Chinese (Taiwan)",
        "Unpin",
        "Unpinned",
        "Unpinned Clips",
        // Commit: complete zh_TW coverage. These keys are now bilingual so the
        // catalog completeness contract enforces Traditional Chinese values.
        "Apply",
        "Cancel",
        "Clear %lld Unpinned Item",
        "Clear %lld Unpinned Items",
        "Clear all clipboard history, including pinned items? This action cannot be undone.",
        "Clear All History…",
        "Clear all unpinned clipboard history? Pinned items are preserved. This action cannot be undone.",
        "Clear clipboard history",
        "Clear Search",
        "Clear the active search query",
        "Clear Unpinned History…",
        "Clip was not saved. Try again.",
        "Copied",
        "Custom",
        "Custom (%lld)",
        "Custom history limit",
        "Delete %lld Item",
        "Delete %lld Items",
        "Delete All %lld Item",
        "Delete All %lld Items",
        "Enter a whole number from %lld to %lld.",
        "Enter text to save a clip.",
        "Focus the clipboard search field",
        "General settings",
        "History actions",
        "History Limit",
        "Items to Be Deleted",
        "Lower History Limit",
        "New Text Clip",
        "Pinned Items Will Be Preserved",
        "Privacy",
        "Save",
        "Search",
        "Search Clipboard History",
        "Search, filter, and clear clipboard history",
        "Search clips",
        "Search history",
        "Settings are not available yet.",
        "This Action Cannot Be Undone",
        "This Includes Pinned Items",
        "This will delete %lld unpinned item to meet the new limit of %@. Pinned items are not affected. This action cannot be undone.",
        "This will delete %lld unpinned items to meet the new limit of %@. Pinned items are not affected. This action cannot be undone.",
        "This will permanently delete %lld unpinned item. %lld pinned item will be preserved. This action cannot be undone.",
        "This will permanently delete %lld unpinned item. %lld pinned items will be preserved. This action cannot be undone.",
        "This will permanently delete %lld unpinned items. %lld pinned item will be preserved. This action cannot be undone.",
        "This will permanently delete %lld unpinned items. %lld pinned items will be preserved. This action cannot be undone.",
        "This will permanently delete all %lld item, including %lld pinned item. This action cannot be undone.",
        "This will permanently delete all %lld item, including %lld pinned items. This action cannot be undone.",
        "This will permanently delete all %lld items, including %lld pinned item. This action cannot be undone.",
        "This will permanently delete all %lld items, including %lld pinned items. This action cannot be undone.",
        "Unlimited",
        "Version",
        "Visual placeholder",
        // Row accessibility (VoiceOver) state and labels.
        "Clipboard clip, %@",
        "Clipboard row surface",
        "Normal",
        "Hovered",
        "Focused",
        "Selected",
        "Inserting",
        "Deleting"
    ]

    private struct Catalog: Decodable {
        let strings: [String: Entry]
    }

    private struct Entry: Decodable {
        let localizations: [String: Localization]?
    }

    private struct Localization: Decodable {
        let stringUnit: StringUnit?
    }

    private struct StringUnit: Decodable {
        let state: String
        let value: String
    }

    private let sourceLiteralPatterns: [NSRegularExpression] = {
        let sourcePatterns = [
            #"\bText\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bButton\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bLabel\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bMenu\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bPicker\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\b(?:Toggle|NavigationLink|LabeledContent|GroupBox|DisclosureGroup)\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bTextField\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bSection\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bSection\s*\(\s*header\s*:\s*"((?:\\.|[^"\\])+)""#,
            #"\bSection\s*\(\s*footer\s*:\s*"((?:\\.|[^"\\])+)""#,
            #"\bSection\s*\(\s*header\s*:\s*"(?:\\.|[^"\\])+"\s*,\s*footer\s*:\s*"((?:\\.|[^"\\])+)""#,
            #"\bText\s*\(\s*LocalizedStringKey\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bSettingsTextHint\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\b(?:SettingsSection|SettingsControlRow|AppToolbar)\s*\([^)]*?\btitle:\s*"((?:\\.|[^"\\])+)""#,
            #"\bSettingsControlRow\s*\([^)]*?\bdescription:\s*"((?:\\.|[^"\\])+)""#,
            #"String\s*\(\s*localized:\s*"((?:\\.|[^"\\])+)""#,
            #"\.nextPasteLocalized\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.localizedString\s*\(\s*forKey:\s*"((?:\\.|[^"\\])+)""#,
            #"\.(?:alert|confirmationDialog|navigationTitle)\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.accessibilityLabel\s*\(\s*Text\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.accessibilityValue\s*\(\s*Text\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.accessibilityHint\s*\(\s*Text\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.help\s*\(\s*Text\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.accessibilityLabel\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.accessibilityValue\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\.help\s*\(\s*"((?:\\.|[^"\\])+)""#
        ]

        return sourcePatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern)
        }
    }()

    private var repoRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var catalogURL: URL {
        repoRootURL
            .appendingPathComponent("NextPaste")
            .appendingPathComponent("Localizable.xcstrings")
    }

    private var projectURL: URL {
        repoRootURL
            .appendingPathComponent("NextPaste.xcodeproj")
            .appendingPathComponent("project.pbxproj")
    }

    private struct LocalizationSourceScanConfiguration {
        let sourceDirectoryURL: URL
        let excludedDirectoryNames: Set<String>

        static func production(repoRootURL: URL) -> Self {
            Self(
                sourceDirectoryURL: repoRootURL.appendingPathComponent("NextPaste"),
                excludedDirectoryNames: ["Debug", "Fixtures"]
            )
        }
    }

    private func loadCatalog() throws -> Catalog {
        let data = try Data(contentsOf: catalogURL)
        return try JSONDecoder().decode(Catalog.self, from: data)
    }

    private func sourceLocalizedStringKeys() throws -> Set<String> {
        try sourceLocalizedStringKeys(
            using: .production(repoRootURL: repoRootURL)
        )
    }

    private func sourceLocalizedStringKeys(
        using configuration: LocalizationSourceScanConfiguration
    ) throws -> Set<String> {
        let sourceDirectoryURL = configuration.sourceDirectoryURL
        guard let enumerator = FileManager.default.enumerator(
            at: sourceDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            Issue.record("Failed to enumerate production source files under \(sourceDirectoryURL.path)")
            return []
        }

        var extracted: Set<String> = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            let path = fileURL.path
            // Ignore generated, archived, and test-only artifacts that are not
            // part of production localization behavior.
            let pathComponents = fileURL.pathComponents
            if configuration.excludedDirectoryNames.contains(where: { pathComponents.contains($0) }) {
                continue
            }

            guard let sourceData = try? Data(contentsOf: fileURL),
                  let sourceText = String(data: sourceData, encoding: .utf8) else {
                Issue.record("Unable to read \(path)")
                continue
            }

            extracted.formUnion(localizedStringKeys(in: sourceText))
        }

        return extracted
    }

    private func localizedStringKeys(in sourceText: String) -> Set<String> {
        var extracted: Set<String> = []
        let nsrange = NSRange(sourceText.startIndex..<sourceText.endIndex, in: sourceText)

        for pattern in sourceLiteralPatterns {
            for match in pattern.matches(in: sourceText, options: [], range: nsrange) {
                guard match.numberOfRanges > 1,
                      let keyRange = Range(match.range(at: 1), in: sourceText) else { continue }
                let key = String(sourceText[keyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if key.isEmpty == false, key.count > 1 {
                    extracted.insert(key)
                }
            }
        }

        // Track literal constants that are deliberately converted to a
        // LocalizedStringKey at the call site. This covers indirect empty-state
        // keys without treating arbitrary model/debug constants as UI text.
        let assignmentPattern = try! NSRegularExpression(
            pattern: #"\b(?:static\s+)?let\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::[^=]+)?=\s*"((?:\\.|[^"\\])+)""#
        )
        for match in assignmentPattern.matches(in: sourceText, range: nsrange) {
            guard let nameRange = Range(match.range(at: 1), in: sourceText),
                  let valueRange = Range(match.range(at: 2), in: sourceText) else { continue }
            let name = String(sourceText[nameRange])
            let referencePattern = try! NSRegularExpression(
                pattern: #"LocalizedStringKey\s*\(\s*(?:Self\.)?"# + NSRegularExpression.escapedPattern(for: name) + #"\s*\)"#
            )
            let isDirectlyReferenced = referencePattern.firstMatch(in: sourceText, range: nsrange) != nil
            let isReturnedByLocalizedComputedProperty = localizedComputedPropertyNames(in: sourceText).contains { propertyName in
                guard let propertyStart = sourceText.range(of: "var \(propertyName)") else { return false }
                let propertySuffix = sourceText[propertyStart.lowerBound...]
                let propertyEnd = propertySuffix.range(of: "\n    private var ")?.lowerBound ?? sourceText.endIndex
                return sourceText[propertyStart.lowerBound..<propertyEnd].contains("Self.\(name)")
            }
            guard isDirectlyReferenced || isReturnedByLocalizedComputedProperty else { continue }
            extracted.insert(String(sourceText[valueRange]))
        }

        return extracted
    }

    private func localizedComputedPropertyNames(in sourceText: String) -> Set<String> {
        let pattern = try! NSRegularExpression(
            pattern: #"LocalizedStringKey\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)"#
        )
        let range = NSRange(sourceText.startIndex..<sourceText.endIndex, in: sourceText)
        return Set(pattern.matches(in: sourceText, range: range).compactMap { match in
            guard let nameRange = Range(match.range(at: 1), in: sourceText) else { return nil }
            return String(sourceText[nameRange])
        })
    }

    private func interpolationSkeleton(_ value: String) -> String {
        let swiftInterpolation = try! NSRegularExpression(pattern: #"\\\([^)]*\)"#)
        let printfPlaceholder = try! NSRegularExpression(
            pattern: #"%(?:\d+\$)?[-+0-9.*]*(?:hh|h|ll|l|L|z|t|j)?[A-Za-z@]"#
        )
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        let withoutSwiftValues = swiftInterpolation.stringByReplacingMatches(
            in: value,
            range: range,
            withTemplate: "<value>"
        )
        let printfRange = NSRange(withoutSwiftValues.startIndex..<withoutSwiftValues.endIndex, in: withoutSwiftValues)
        return printfPlaceholder.stringByReplacingMatches(
            in: withoutSwiftValues,
            range: printfRange,
            withTemplate: "<value>"
        )
    }

    private func supportedLocales() throws -> [String] {
        let project = try String(contentsOf: projectURL, encoding: .utf8)
        guard let knownRegionsStart = project.range(of: "knownRegions = ("),
              let knownRegionsEnd = project[knownRegionsStart.upperBound...].range(of: ");")
        else {
            Issue.record("Could not parse knownRegions from \(projectURL.path)")
            return []
        }

        return project[knownRegionsStart.upperBound..<knownRegionsEnd.lowerBound]
            .split(separator: "\n")
            .map { line in
                line.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",\""))
                )
            }
            .filter { $0.isEmpty == false && $0 != "Base" }
    }

    @Test func stringCatalogContainsBranchFeatureLocalizationKeys() throws {
        let catalog = try loadCatalog()
        let requiredKeys: Set<String> = [
            "1–1000",
            "A clipboard manager for Apple platforms.",
            "About",
            "About NextPaste",
            "Appearance",
            "App Language",
            "Apply",
            "At least one modifier is required.",
            "Cancel",
            "Cancel Recording",
            "Changes apply immediately throughout NextPaste.",
            "Choose a different filter.",
            "Clear %lld Unpinned Item",
            "Clear %lld Unpinned Items",
            "Clear all clipboard history, including pinned items? This action cannot be undone.",
            "Clear All History",
            "Clear All History…",
            "Clear all unpinned clipboard history? Pinned items are preserved. This action cannot be undone.",
            "Clear Search",
            "Clear Shortcut",
            "Clear Unpinned History",
            "Clear Unpinned History…",
            "Clear clipboard history",
            "Clear the active search query",
            "Clip was not saved. Try again.",
            "Clips",
            "Close",
            "Command",
            "Command-F is used for search.",
            "Command-, is used for Settings.",
            "Control",
            "Copy",
            "Copy Image Text",
            "Copy Original Image",
            "Current global shortcut",
            "Custom",
            "Custom (%lld)",
            "Custom history limit",
            "Dark",
            "Data & Privacy",
            "Delete",
            "Delete %lld Item",
            "Delete %lld Items",
            "Delete All %lld Item",
            "Delete All %lld Items",
            "Disable the global keyboard shortcut",
            "Enter a whole number from %lld to %lld.",
            "Enter text to save a clip.",
            "English (United States)",
            "Escape",
            "Find…",
            "Focus the clipboard search field",
            "Follow System",
            "General",
            "General settings",
            "Global Shortcut",
            "History",
            "History Limit",
            "History limit could not be applied. Try again.",
            "Complete suspended OCR",
            "Image Clips",
            "Image Text Recognition Failed",
            "Keep up to %lld unpinned clipboard items. Pinned items are always kept.",
            "Language",
            "History actions",
            "Light",
            "Lower History Limit",
            "Minimize",
            "New Clip",
            "New Text Clip",
            "NextPaste keeps your clipboard history on this Mac. Content is stored locally and is never sent to a server.",
            "No clips match this filter",
            "None",
            "No Text Found in Image",
            "Option",
            "Option alone cannot be a shortcut.",
            "Permanently remove clipboard history. Pinned items are preserved when clearing unpinned history only.",
            "Pin",
            "Pinned",
            "Press a key combination…",
            "Quit",
            "Record Shortcut",
            "Record a new global keyboard shortcut",
            "Recognizing Image Text",
            "Recognizing Image Text…",
            "Reset to Default",
            "Restore the default global keyboard shortcut",
            "Return",
            "Retry Copy Image Text",
            "Save",
            "Search",
            "Search Clipboard History",
            "Search, filter, and clear clipboard history",
            "Search clips",
            "Search history",
            "Settings",
            "Settings are not available yet.",
            "Shift",
            "Shortcut is already in use.",
            "Shortcuts",
            "Space",
            "Storage Limit",
            "Storage Limit Range",
            "Storage Limit Value",
            "Tab",
            "This shortcut conflicts with the %@ menu command.",
            "Traditional Chinese (Taiwan)",
            "This will delete %lld unpinned item to meet the new limit of %@. Pinned items are not affected. This action cannot be undone.",
            "This will delete %lld unpinned items to meet the new limit of %@. Pinned items are not affected. This action cannot be undone.",
            "This will permanently delete %lld unpinned item. %lld pinned item will be preserved. This action cannot be undone.",
            "This will permanently delete %lld unpinned item. %lld pinned items will be preserved. This action cannot be undone.",
            "This will permanently delete %lld unpinned items. %lld pinned item will be preserved. This action cannot be undone.",
            "This will permanently delete %lld unpinned items. %lld pinned items will be preserved. This action cannot be undone.",
            "This will permanently delete all %lld item, including %lld pinned item. This action cannot be undone.",
            "This will permanently delete all %lld item, including %lld pinned items. This action cannot be undone.",
            "This will permanently delete all %lld items, including %lld pinned item. This action cannot be undone.",
            "This will permanently delete all %lld items, including %lld pinned items. This action cannot be undone.",
            "Unlimited",
            "Unpin",
            "Unpinned",
            "Version",
            "Visual placeholder",
            "A single key without modifiers cannot be a shortcut."
        ]

        let missingKeys = requiredKeys.subtracting(catalog.strings.keys)
        if missingKeys.isEmpty == false {
            Issue.record("Missing localization keys: \(missingKeys.sorted())")
        }
        #expect(missingKeys.isEmpty)
    }

    @Test func stringCatalogHasTranslatedValuesForProjectSupportedLocales() throws {
        let catalog = try loadCatalog()
        let locales = try supportedLocales()

        if locales.isEmpty {
            Issue.record("Expected at least one project locale.")
            return
        }

        #expect(Set(locales).isSuperset(of: ["en", "zh-Hant"]))

        for locale in locales {
            let missingKeys = catalog.strings.compactMap { key, entry -> String? in
                guard let localizations = entry.localizations else { return key }
                guard let localization = localizations[locale],
                      let stringUnit = localization.stringUnit,
                      stringUnit.state == "translated",
                      stringUnit.value.isEmpty == false
                else {
                    return key
                }
                return nil
            }

            if missingKeys.isEmpty == false {
                Issue.record("Locale \(locale) is missing translations for keys: \(missingKeys.sorted())")
            }
            #expect(missingKeys.isEmpty)
        }
    }

    @Test func featureKeysHaveConcreteEnglishAndTraditionalChineseValues() throws {
        let catalog = try loadCatalog()

        for key in featureBilingualKeys {
            guard let entry = catalog.strings[key] else {
                Issue.record("Feature localization key is missing: \(key)")
                continue
            }

            for locale in ["en", "zh-Hant"] {
                guard let stringUnit = entry.localizations?[locale]?.stringUnit,
                      stringUnit.state == "translated",
                      stringUnit.value.isEmpty == false else {
                    Issue.record("Feature key \(key) has no concrete \(locale) translation")
                    continue
                }
            }
        }
    }

    @Test func compiledAppBundleContainsEveryFeatureStringForBothLocales() throws {
        let appBundle = Bundle(for: ClipItem.self)
        let catalog = try loadCatalog()

        for locale in ["en", "zh-Hant"] {
            guard let localeDirectoryURL = appBundle.url(forResource: locale, withExtension: "lproj"),
                  let localizedBundle = Bundle(url: localeDirectoryURL) else {
                Issue.record("Built app bundle has no \(locale).lproj localization resource")
                continue
            }

            for key in catalog.strings.keys {
                let expected = try #require(catalog.strings[key]?.localizations?[locale]?.stringUnit?.value)
                let compiled = localizedBundle.localizedString(
                    forKey: key,
                    value: "__NEXTPASTE_MISSING_LOCALIZATION__",
                    table: "Localizable"
                )
                #expect(compiled == expected)
            }
        }
    }

    @Test func sourceLocalizedLiteralsAllExistInCatalog() throws {
        let catalog = try loadCatalog()
        let sourceKeys = try sourceLocalizedStringKeys()

        let catalogSkeletons = Set(catalog.strings.keys.map(interpolationSkeleton))
        let missing = sourceKeys.filter { key in
            catalog.strings[key] == nil && catalogSkeletons.contains(interpolationSkeleton(key)) == false
        }
        if missing.isEmpty == false {
            Issue.record("Production localized call sites reference keys missing from Localizable.xcstrings: \(missing.sorted())")
        }
        #expect(missing.isEmpty)
    }

    @Test func scannerCoversSwiftUITitleInitializersAndExcludesNonlocalizedLiterals() {
        let source = #"""
        static let headline = "No clips yet"
        static let searchHeadline = "No matching clips"
        private var headline: String { Self.searchHeadline }
        Text(LocalizedStringKey(headline))
        Text(LocalizedStringKey("Localized text key"))
        Text("Delete \(count) Items")
        SettingsTextHint("Global Shortcut")
        Label("New Clip", systemImage: "plus")
        Toggle("Toggle title", isOn: $isEnabled)
        NavigationLink("Navigation title") { EmptyView() }
        LabeledContent("Labeled content title") { EmptyView() }
        GroupBox("Group box title") { EmptyView() }
        DisclosureGroup("Disclosure group title") { EmptyView() }
        Section(header: "Section header", footer: "Section footer") { EmptyView() }
        .confirmationDialog("Clear All History", isPresented: $isPresented) { }
        let runtimeTitle = "Runtime title"
        Text(runtimeTitle)
        Text(verbatim: "Verbatim text")
        Toggle(runtimeTitle, isOn: $isEnabled)
        print("Debug literal")
        """#

        let keys = localizedStringKeys(in: source)
        #expect(keys.contains("No clips yet"))
        #expect(keys.contains("No matching clips"))
        #expect(keys.contains("Localized text key"))
        #expect(keys.contains(#"Delete \(count) Items"#))
        #expect(keys.contains("Global Shortcut"))
        #expect(keys.contains("New Clip"))
        #expect(keys.contains("Toggle title"))
        #expect(keys.contains("Navigation title"))
        #expect(keys.contains("Labeled content title"))
        #expect(keys.contains("Group box title"))
        #expect(keys.contains("Disclosure group title"))
        #expect(keys.contains("Section header"))
        #expect(keys.contains("Section footer"))
        #expect(keys.contains("Clear All History"))
        #expect(keys.contains("Runtime title") == false)
        #expect(keys.contains("Verbatim text") == false)
        #expect(keys.contains("Debug literal") == false)
        #expect(interpolationSkeleton(#"Delete \(count) Items"#) == interpolationSkeleton("Delete %lld Items"))
    }

    @Test func sourceScannerHonorsConfigurableDirectoryExclusions() throws {
        let fileManager = FileManager.default
        let scanRoot = fileManager.temporaryDirectory
            .appendingPathComponent("nextpaste-localization-scan-\(UUID().uuidString)", isDirectory: true)
        let includedDirectory = scanRoot.appendingPathComponent("Included", isDirectory: true)
        let excludedDirectory = scanRoot.appendingPathComponent("Excluded", isDirectory: true)
        try fileManager.createDirectory(at: includedDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: excludedDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: scanRoot) }

        try Data(#"Text("Included localized literal")"#.utf8)
            .write(to: includedDirectory.appendingPathComponent("Included.swift"), options: .atomic)
        try Data(#"Text("Excluded localized literal")"#.utf8)
            .write(to: excludedDirectory.appendingPathComponent("Excluded.swift"), options: .atomic)

        let keys = try sourceLocalizedStringKeys(
            using: LocalizationSourceScanConfiguration(
                sourceDirectoryURL: scanRoot,
                excludedDirectoryNames: ["Excluded"]
            )
        )

        #expect(keys.contains("Included localized literal"))
        #expect(keys.contains("Excluded localized literal") == false)
    }

    @Test func unknownLocaleFallsBackToANonemptyLocalizedValue() {
        let value = String(
            localized: "Copy Original Image",
            defaultValue: "Copy Original Image",
            bundle: Bundle(for: ClipItem.self),
            locale: Locale(identifier: "zz-ZZ")
        )

        #expect(value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty == false)
    }
}
