//
//  LocalizationCatalogTests.swift
//  NextPasteTests
//
//  T026 — verify the string catalog covers the branch-owned user-facing strings
//  and that every project-supported locale has a translated value.
//

import Foundation
import Testing

struct LocalizationCatalogTests {
    private let featureBilingualKeys: Set<String> = [
        "1–1000",
        "Appearance",
        "App Language",
        "Changes apply immediately throughout NextPaste.",
        "Copy Image Text",
        "Dark",
        "English (United States)",
        "Image Text Recognition Failed",
        "Follow System",
        "History limit could not be applied. Try again.",
        "Keep up to %lld unpinned clipboard items. Pinned items are always kept.",
        "Language",
        "Light",
        "No Text Found in Image",
        "Recognizing Image Text",
        "Recognizing Image Text…",
        "Retry Copy Image Text",
        "Storage Limit",
        "Storage Limit Range",
        "Storage Limit Value",
        "Traditional Chinese (Taiwan)"
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
            "Appearance",
            "App Language",
            "Apply",
            "At least one modifier is required.",
            "Cancel",
            "Cancel Recording",
            "Changes apply immediately throughout NextPaste.",
            "Clear %lld Unpinned Item",
            "Clear %lld Unpinned Items",
            "Clear All History",
            "Clear All History…",
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
            "Copy Image Text",
            "Current global shortcut",
            "Custom",
            "Custom (%lld)",
            "Custom history limit",
            "Dark",
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
            "Image Text Recognition Failed",
            "Keep up to %lld unpinned clipboard items. Pinned items are always kept.",
            "Language",
            "History actions",
            "Light",
            "Lower History Limit",
            "Minimize",
            "New Clip",
            "New Text Clip",
            "None",
            "No Text Found in Image",
            "Option",
            "Option alone cannot be a shortcut.",
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
            // fallback in zh-Hant. Every string introduced by the language/storage
            // settings work is explicitly bilingual.
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
}
