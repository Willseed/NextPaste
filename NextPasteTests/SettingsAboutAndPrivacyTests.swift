//
//  SettingsAboutAndPrivacyTests.swift
//  NextPasteTests
//
//  Verify the About tab and Data & Privacy section strings added to the
//  Settings view resolve to non-empty, correct values for both en and
//  zh-Hant in the compiled app bundle.
//

import Foundation
import Testing
@testable import NextPaste

struct SettingsAboutAndPrivacyTests {
    private let appBundle = Bundle(for: ClipItem.self)

    private struct ExpectedString {
        let key: String
        let en: String
        let zhHant: String
    }

    /// The nine catalog keys added for the About tab and the Data & Privacy
    /// section, paired with their expected translated values per locale.
    private let settingsStrings: [ExpectedString] = [
        .init(
            key: "About",
            en: "About",
            zhHant: "關於"
        ),
        .init(
            key: "Data & Privacy",
            en: "Data & Privacy",
            zhHant: "資料與隱私"
        ),
        .init(
            key: "Version",
            en: "Version",
            zhHant: "版本"
        ),
        .init(
            key: "About NextPaste",
            en: "About NextPaste",
            zhHant: "關於 NextPaste"
        ),
        .init(
            key: "A clipboard manager for Apple platforms.",
            en: "A clipboard manager for Apple platforms.",
            zhHant: "適用於 Apple 平台的剪貼簿管理工具。"
        ),
        .init(
            key: "NextPaste keeps your clipboard history on this Mac. Content is stored locally and is never sent to a server.",
            en: "NextPaste keeps your clipboard history on this Mac. Content is stored locally and is never sent to a server.",
            zhHant: "NextPaste 會將剪貼簿歷史記錄保留在此 Mac 上。內容儲存於本機，不會傳送至任何伺服器。"
        ),
        .init(
            key: "Permanently remove clipboard history. Pinned items are preserved when clearing unpinned history only.",
            en: "Permanently remove clipboard history. Pinned items are preserved when clearing unpinned history only.",
            zhHant: "永久移除剪貼簿歷史記錄。僅清除未釘選歷史記錄時會保留已釘選項目。"
        ),
        .init(
            key: "Clear all unpinned clipboard history? Pinned items are preserved. This action cannot be undone.",
            en: "Clear all unpinned clipboard history? Pinned items are preserved. This action cannot be undone.",
            zhHant: "要清除所有未釘選的剪貼簿歷史記錄嗎？將保留已釘選項目。此操作無法復原。"
        ),
        .init(
            key: "Clear all clipboard history, including pinned items? This action cannot be undone.",
            en: "Clear all clipboard history, including pinned items? This action cannot be undone.",
            zhHant: "要清除所有剪貼簿歷史記錄嗎？此操作會包含已釘選項目，且無法復原。"
        )
    ]

    private func localizedBundle(for locale: String) throws -> Bundle {
        let localeDir = try #require(appBundle.url(forResource: locale, withExtension: "lproj"))
        return try #require(Bundle(url: localeDir))
    }

    @Test func settingsAboutAndPrivacyStringsResolveForBothLocales() throws {
        let enBundle = try localizedBundle(for: "en")
        let zhHantBundle = try localizedBundle(for: "zh-Hant")

        for expected in settingsStrings {
            let enValue = enBundle.localizedString(
                forKey: expected.key,
                value: "__NEXTPASTE_MISSING_LOCALIZATION__",
                table: "Localizable"
            )
            #expect(enValue.isEmpty == false, "en value for \"\(expected.key)\" was empty")
            #expect(enValue == expected.en, "en value for \"\(expected.key)\" was \"\(enValue)\"")

            let zhValue = zhHantBundle.localizedString(
                forKey: expected.key,
                value: "__NEXTPASTE_MISSING_LOCALIZATION__",
                table: "Localizable"
            )
            #expect(zhValue.isEmpty == false, "zh-Hant value for \"\(expected.key)\" was empty")
            #expect(zhValue == expected.zhHant, "zh-Hant value for \"\(expected.key)\" was \"\(zhValue)\"")
        }
    }

    @Test func aboutTabAppNameAndVersionLabelLocalizeCorrectly() throws {
        let enBundle = try localizedBundle(for: "en")
        let zhHantBundle = try localizedBundle(for: "zh-Hant")

        let aboutTitle = enBundle.localizedString(
            forKey: "About NextPaste",
            value: "__NEXTPASTE_MISSING_LOCALIZATION__",
            table: "Localizable"
        )
        #expect(aboutTitle == "About NextPaste")

        let aboutTitleZh = zhHantBundle.localizedString(
            forKey: "About NextPaste",
            value: "__NEXTPASTE_MISSING_LOCALIZATION__",
            table: "Localizable"
        )
        #expect(aboutTitleZh == "關於 NextPaste")

        let versionLabel = enBundle.localizedString(
            forKey: "Version",
            value: "__NEXTPASTE_MISSING_LOCALIZATION__",
            table: "Localizable"
        )
        #expect(versionLabel == "Version")

        let versionLabelZh = zhHantBundle.localizedString(
            forKey: "Version",
            value: "__NEXTPASTE_MISSING_LOCALIZATION__",
            table: "Localizable"
        )
        #expect(versionLabelZh == "版本")
    }
}