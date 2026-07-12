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
            #"\bTextField\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"\bSection\s*\(\s*"((?:\\.|[^"\\])+)""#,
            #"String\s*\(\s*localized:\s*"((?:\\.|[^"\\])+)""#,
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

    private func loadCatalog() throws -> Catalog {
        let data = try Data(contentsOf: catalogURL)
        return try JSONDecoder().decode(Catalog.self, from: data)
    }

    private func sourceLocalizedStringKeys() throws -> Set<String> {
        let nextPasteDirectory = repoRootURL.appendingPathComponent("NextPaste")
        guard let enumerator = FileManager.default.enumerator(
            at: nextPasteDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            Issue.record("Failed to enumerate production source files under \(nextPasteDirectory.path)")
            return []
        }

        var extracted: Set<String> = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            let path = fileURL.path
            // Ignore generated, archived, and test-only artifacts that are not
            // part of production localization behavior.
            if path.contains("/Debug/") || path.contains("/Fixtures/") {
                continue
            }

            guard let sourceData = try? Data(contentsOf: fileURL),
                  let sourceText = String(data: sourceData, encoding: .utf8) else {
                Issue.record("Unable to read \(path)")
                continue
            }

            for pattern in sourceLiteralPatterns {
                let nsrange = NSRange(sourceText.startIndex..<sourceText.endIndex, in: sourceText)
                for match in pattern.matches(in: sourceText, options: [], range: nsrange) {
                    guard match.numberOfRanges > 1 else { continue }
                    guard let keyRange = Range(match.range(at: 1), in: sourceText) else { continue }
                    var key = String(sourceText[keyRange])
                    key = key.trimmingCharacters(in: .whitespacesAndNewlines)
                    if key.isEmpty { continue }
                    if key.contains("\\(") { continue }
                    if key.count == 1 { continue }
                    extracted.insert(key)
                }
            }
        }

        return extracted
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
            // Skip comment-only/metadata catalog entries (keys with no
            // `localizations` field, e.g. the app name, an illustration label,
            // and an auto-generated format-string comment). These are not
            // translatable strings; the completeness contract applies only to
            // entries that actually declare localizations.
            // Existing English-only entries intentionally use the String Catalog
            // fallback in zh-Hant. Settings, shortcut, and branch-owned image-action
            // strings are explicitly bilingual.
            let entriesToValidate = locale == "en"
                ? catalog.strings
                : catalog.strings.filter { featureBilingualKeys.contains($0.key) }
            let missingKeys = entriesToValidate.compactMap { key, entry -> String? in
                guard let localizations = entry.localizations else { return nil }
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

            for key in featureBilingualKeys {
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

        let missing = sourceKeys.subtracting(catalog.strings.keys)
        if missing.isEmpty == false {
            Issue.record("Production localized call sites reference keys missing from Localizable.xcstrings: \(missing.sorted())")
        }
        #expect(missing.isEmpty)
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
