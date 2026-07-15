//
//  SettingsPresentationContractTests.swift
//  NextPasteTests
//
//  Source-level guards for native Settings presentation choices that are not
//  represented reliably in the accessibility hierarchy.
//

import Foundation
import Testing
#if os(macOS)
import AppKit
import SwiftUI
@testable import NextPaste
#endif

struct SettingsPresentationContractTests {
    @Test func appearancePickerHidesItsRedundantVisualLabel() throws {
        let source = try settingsSource()
        let appearanceControl = try fragment(
            in: source,
            from: "SettingsControlRow(\n                        title: \"Appearance\"",
            to: ".onChange(of: appearancePreference.mode)"
        )

        #expect(appearanceControl.contains("Picker(\"Appearance\""))
        #expect(appearanceControl.contains(".pickerStyle(.menu)"))
        #expect(appearanceControl.contains(".labelsHidden()"))
        #expect(appearanceControl.contains(".accessibilityLabel(Text(\"Appearance\"))") == false)
    }

    @MainActor
    @Test func historyLimitSliderHidesTicksAndKeepsUnitAccessibilityAdjustments() throws {
#if os(macOS)
        var boundValue = 155.0
        var editingEvents: [Bool] = []
        let control = HistoryLimitSliderControl(
            value: Binding(
                get: { boundValue },
                set: { boundValue = $0 }
            ),
            accessibilityLabel: "Storage Limit",
            onEditingChanged: { editingEvents.append($0) }
        )
        let coordinator = control.makeCoordinator()
        let slider = HistoryLimitSliderControl.makeSlider(
            value: 155,
            accessibilityLabel: "Storage Limit"
        )
        slider.target = coordinator
        slider.action = #selector(HistoryLimitSliderControl.Coordinator.valueChanged(_:))

        #expect(slider.cell is HistoryLimitSliderCell)
        #expect(slider.numberOfTickMarks == 0)
        #expect(slider.allowsTickMarkValuesOnly == false)
        #expect(slider.isContinuous)
        #expect(slider.cell?.accessibilityIdentifier() == "history-limit-slider")
        #expect(slider.cell?.accessibilityLabel() == "Storage Limit")

        slider.accessibilityPerformIncrement()
        #expect(slider.doubleValue == 156)
        #expect(boundValue == 156)
        slider.accessibilityPerformDecrement()
        #expect(slider.doubleValue == 155)
        #expect(boundValue == 155)
        #expect(editingEvents == [false, false])
#endif
    }

    private func settingsSource() throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent("NextPaste/SettingsView.swift"),
            encoding: .utf8
        )
    }

    private func fragment(
        in source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(
            source.range(of: endMarker, range: start.upperBound..<source.endIndex)
        )
        return String(source[start.lowerBound..<end.lowerBound])
    }
}
