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
                    in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ","))
                )
            }
            .filter { $0.isEmpty == false && $0 != "Base" }
    }

    @Test func stringCatalogContainsBranchFeatureLocalizationKeys() throws {
        let catalog = try loadCatalog()
        let requiredKeys: Set<String> = [
            "Appearance",
            "Apply",
            "At least one modifier is required.",
            "Cancel",
            "Cancel Recording",
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
            "Escape",
            "Find…",
            "Focus the clipboard search field",
            "Follow System",
            "General",
            "General settings",
            "Global Shortcut",
            "History",
            "History Limit",
            "History actions",
            "Light",
            "Lower History Limit",
            "Minimize",
            "New Clip",
            "New Text Clip",
            "None",
            "Option",
            "Option alone cannot be a shortcut.",
            "Press a key combination…",
            "Quit",
            "Record Shortcut",
            "Record a new global keyboard shortcut",
            "Reset to Default",
            "Restore the default global keyboard shortcut",
            "Return",
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
            "Tab",
            "This shortcut conflicts with the %@ menu command.",
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

        for locale in locales {
            // Skip comment-only/metadata catalog entries (keys with no
            // `localizations` field, e.g. the app name, an illustration label,
            // and an auto-generated format-string comment). These are not
            // translatable strings; the completeness contract applies only to
            // entries that actually declare localizations.
            let missingKeys = catalog.strings.compactMap { key, entry -> String? in
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
}
