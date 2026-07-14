//
//  HistoryPage.swift
//  NextPasteUITests
//

import XCTest

@MainActor
struct HistoryPage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Search

    func searchField(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identified = app.searchFields[ClipboardFixture.Search.identifier]
        if identified.waitForExistence(timeout: timeout) { return identified }
        let byPrompt = app.searchFields[ClipboardFixture.Search.prompt]
        if byPrompt.waitForExistence(timeout: timeout) { return byPrompt }
        XCTAssertTrue(
            app.textFields[ClipboardFixture.Search.prompt].waitForExistence(timeout: timeout),
            "Expected native search field",
            file: file,
            line: line
        )
        return app.textFields[ClipboardFixture.Search.prompt]
    }

    func enterSearchQuery(
        _ query: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = searchField(file: file, line: line)
        field.tap()
        field.typeText(query)
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                (field.value as? String) == query
            },
            "Expected native search field to contain \(query)",
            file: file,
            line: line
        )
    }

    func clearSearch(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = searchField(file: file, line: line)
        field.tap()
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(.delete, modifierFlags: [])
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                (field.value as? String)?.isEmpty == true
            },
            "Expected native search field to clear before the next interaction",
            file: file,
            line: line
        )
    }

    func searchButton(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.buttons["search-button"].waitForExistence(timeout: timeout),
            "Expected Search button",
            file: file,
            line: line
        )
        return app.buttons["search-button"]
    }

    func clearSearchButton(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.buttons["clear-search-button"].waitForExistence(timeout: timeout),
            "Expected Clear Search button",
            file: file,
            line: line
        )
        return app.buttons["clear-search-button"]
    }

    // MARK: - Overflow / clear menu

    func historyOverflowMenu(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.descendants(matching: .any)["history-overflow-menu"].waitForExistence(timeout: timeout),
            "Expected history overflow menu",
            file: file,
            line: line
        )
        return app.descendants(matching: .any)["history-overflow-menu"]
    }

    func clearUnpinnedMenuItem(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.descendants(matching: .any)["menu-clear-unpinned-history"].waitForExistence(timeout: timeout),
            "Expected Clear Unpinned History menu item",
            file: file,
            line: line
        )
        return app.descendants(matching: .any)["menu-clear-unpinned-history"]
    }

    func clearAllMenuItem(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.descendants(matching: .any)["menu-clear-all-history"].waitForExistence(timeout: timeout),
            "Expected Clear All History menu item",
            file: file,
            line: line
        )
        return app.descendants(matching: .any)["menu-clear-all-history"]
    }

    // MARK: - History list surface

    func historyList(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.descendants(matching: .any)["clip-history-list"].waitForExistence(timeout: timeout),
            "Expected clip history list to exist",
            file: file,
            line: line
        )
        return app.descendants(matching: .any)["clip-history-list"]
    }

    func historySurface(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.descendants(matching: .any)["history-surface"].waitForExistence(timeout: timeout),
            "Expected history surface",
            file: file,
            line: line
        )
        return app.descendants(matching: .any)["history-surface"]
    }

    func singleColumnLayout(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.descendants(matching: .any)["single-column-history-layout"].waitForExistence(timeout: timeout),
            "Expected single-column history layout",
            file: file,
            line: line
        )
        return app.descendants(matching: .any)["single-column-history-layout"]
    }

    // MARK: - Row access

    func row(
        withText text: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "clip-row-",
            text
        )
        let element = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected row containing \(text)",
            file: file,
            line: line
        )
        return element
    }

    func assertRowExists(
        withText text: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        _ = row(withText: text, timeout: timeout, file: file, line: line)
    }

    func assertRowNeverAppears(
        withText text: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            app.staticTexts[text].waitForExistence(timeout: timeout),
            "Expected row containing \(text) to never appear",
            file: file,
            line: line
        )
    }

    func assertRowEventuallyDisappears(
        withText text: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.staticTexts[text].waitForNonExistence(timeout: timeout),
            "Expected row containing \(text) to eventually disappear",
            file: file,
            line: line
        )
    }

    // MARK: - Create text clip

    func createTextClip(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let newClipButton = app.buttons["new-clip-button"]
        XCTAssertTrue(newClipButton.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected New Clip button", file: file, line: line)
        newClipButton.tap()

        let editor = app.textViews["clip-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10),
                      "Expected clip text editor", file: file, line: line)
        editor.tap()
        editor.typeText(text)

        let saveButton = app.buttons["save-clip-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected Save Clip button", file: file, line: line)
        saveButton.tap()

        let historyList = app.descendants(matching: .any)["clip-history-list"]
        let searchEmpty = app.staticTexts["search-empty-state-title"]
        let historyEmpty = app.staticTexts["empty-state-title"]
        XCTAssertTrue(
            historyList.waitForExistence(timeout: ClipboardFixture.defaultTimeout)
                || searchEmpty.waitForExistence(timeout: 1)
                || historyEmpty.waitForExistence(timeout: 1),
            "Expected history surface to return after saving a clip",
            file: file,
            line: line
        )
    }

    func createTextClips(
        _ texts: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        for text in texts {
            try createTextClip(text, file: file, line: line)
        }
    }

    // MARK: - Visible rows (viewport-intersecting)

    func firstVisibleClipRow(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        _ = historyList(timeout: timeout, file: file, line: line)
        let rows = visibleClipRows()
        if let first = rows.first {
            XCTAssertTrue(first.exists, "Expected a visible clip row", file: file, line: line)
            return first
        }
        let fallback = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")).firstMatch
        XCTAssertTrue(fallback.waitForExistence(timeout: timeout),
                      "Expected a visible clip row", file: file, line: line)
        return fallback
    }

    func assertFirstVisibleClipRowFullyVisibleBelowFixedHeader(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let list = historyList(timeout: timeout, file: file, line: line)
        let firstRow = firstVisibleClipRow(timeout: timeout, file: file, line: line)
        let headerBottom = fixedHeaderBottom()
        XCTAssertGreaterThanOrEqual(firstRow.frame.minY, headerBottom,
                                    "Expected the first visible row to start below the fixed header region",
                                    file: file, line: line)
        XCTAssertGreaterThanOrEqual(firstRow.frame.minY, list.frame.minY,
                                    "Expected the first visible row to stay within the history viewport",
                                    file: file, line: line)
        XCTAssertLessThanOrEqual(firstRow.frame.maxY, list.frame.maxY,
                                 "Expected the first visible row to remain fully inside the history viewport",
                                 file: file, line: line)
    }

    func assertFirstVisibleClipRowContains(
        _ expectedText: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let firstRow = firstVisibleClipRow(timeout: timeout, file: file, line: line)
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: firstRow)
                .localizedCaseInsensitiveContains(expectedText),
            "Expected first visible row to contain \(expectedText)",
            file: file,
            line: line
        )
    }

    func fixedHeaderBottom() -> CGFloat {
        var lower = app.descendants(matching: .any)["app-toolbar"].frame.maxY
        let sf = app.searchFields.firstMatch
        if sf.exists { lower = max(lower, sf.frame.maxY) }
        let tf = app.textFields.firstMatch
        if tf.exists { lower = max(lower, tf.frame.maxY) }
        let ph = app.staticTexts["settings-placeholder-message"]
        if ph.exists { lower = max(lower, ph.frame.maxY) }
        return lower
    }

    /// Visible rows must intersect the history list viewport — not just have frame > 0.
    func visibleClipRows() -> [XCUIElement] {
        let list = app.descendants(matching: .any)["clip-history-list"]
        let listFrame = list.exists ? list.frame : .zero
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        return app.descendants(matching: .any)
            .matching(predicate)
            .allElementsBoundByIndex
            .filter { element in
                guard element.exists else { return false }
                let f = element.frame
                guard f.width > 0, f.height > 0 else { return false }
                guard list.exists else { return true }
                return f.intersects(listFrame)
            }
            .sorted { lhs, rhs in
                lhs.frame.minY == rhs.frame.minY
                    ? lhs.frame.minX < rhs.frame.minX
                    : lhs.frame.minY < rhs.frame.minY
            }
    }

    func visibleClipRowsDescription() -> String {
        let rows = visibleClipRows()
        guard rows.isEmpty == false else { return "No visible clip rows found." }
        return rows.enumerated()
            .map { index, row in
                let f = row.frame
                return "\(index): exists=\(row.exists) hittable=\(row.isHittable) frame=(x:\(f.minX), y:\(f.minY), w:\(f.width), h:\(f.height)) label='\(row.label)' id='\(row.identifier)'"
            }
            .joined(separator: "\n")
    }

    // MARK: - Clip row count

    func clipRowCount() -> Int {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        return app.descendants(matching: .any).matching(predicate).count
    }

    func assertClipRowIdentifierExists(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        XCTAssertTrue(
            app.descendants(matching: .any).matching(predicate).element.waitForExistence(timeout: timeout),
            "Expected a migrated clip row identifier",
            file: file,
            line: line
        )
    }

    func assertFullTextLabelAbsent(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let pred = NSPredicate(format: "label == %@", text)
        XCTAssertFalse(
            app.staticTexts.matching(pred).element.exists,
            "Expected full text label to be absent",
            file: file,
            line: line
        )
    }

    // MARK: - Marker values

    func visibleClipCount() -> Int? { markerValue("history-visible-count") }
    func visibleTextClipCount() -> Int? { markerValue("history-visible-text-count") }
    func visibleImageClipCount() -> Int? { markerValue("history-visible-image-count") }
    func visiblePinnedClipCount() -> Int? { markerValue("history-visible-pinned-count") }
    func visibleUniqueClipCount() -> Int? { markerValue("history-visible-unique-count") }
    func visibleIntegrityDigest() -> String? { markerStringValue("history-visible-integrity-digest") }

    func assertVisibleClipCount(
        _ expected: Int,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertMarkerValue("history-visible-count", equals: expected, timeout: timeout, file: file, line: line)
    }

    func assertVisibleDatasetCounts(
        total: Int, text: Int, image: Int, pinned: Int,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expected = [total, text, image, pinned, total]
        var observed: [Int]?
        let matched = UITestWait.until(timeout: timeout) {
            observed = datasetCounts()
            return observed == expected
        }
        XCTAssertTrue(
            matched,
            "Expected visible dataset counts \(expected), got \(observed ?? [])",
            file: file,
            line: line
        )
    }

    func launchReadinessDuration(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TimeInterval {
        var duration: TimeInterval?
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                guard let raw = markerStringValue("history-launch-readiness-duration"),
                      let parsed = TimeInterval(raw), parsed.isFinite else { return false }
                duration = parsed
                return true
            },
            "Expected a frozen rendered history launch readiness duration",
            file: file,
            line: line
        )
        return duration ?? .infinity
    }

    // MARK: - Search empty state

    func assertSearchEmptyState(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.staticTexts["search-empty-state-title"].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected search-empty state title",
            file: file,
            line: line
        )
        XCTAssertEqual(
            ClipboardFixture.accessibleText(of: app.staticTexts["search-empty-state-title"]),
            ClipboardFixture.Search.emptyStateTitle,
            file: file,
            line: line
        )
        XCTAssertEqual(
            ClipboardFixture.accessibleText(of: app.staticTexts["search-empty-state-description"]),
            ClipboardFixture.Search.emptyStateDescription,
            file: file,
            line: line
        )
    }

    func assertSearchEmptyStateNeverAppears(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            app.staticTexts["search-empty-state-title"].waitForExistence(timeout: timeout),
            "Expected search-empty state to never appear",
            file: file,
            line: line
        )
    }

    func assertSearchFieldContains(
        _ text: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = searchField(file: file, line: line)
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                ClipboardFixture.combinedAccessibilityText(of: field)
                    .localizedCaseInsensitiveContains(text)
            },
            "Expected search field to contain \(text) within \(timeout) seconds",
            file: file,
            line: line
        )
    }

    // MARK: - Copy feedback

    func assertCopiedFeedback(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let pred = NSPredicate(
            format: "identifier == %@ AND label == %@",
            ClipboardFixture.ImageClipboard.Accessibility.copyFeedbackIdentifier,
            ClipboardFixture.ImageClipboard.Accessibility.copyFeedbackLabel
        )
        XCTAssertTrue(
            app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: timeout),
            "Expected copied feedback with its accessible label",
            file: file,
            line: line
        )
    }

    func assertCopiedFeedbackNeverAppears(
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            copyFeedbackElement().waitForExistence(timeout: timeout),
            "Expected copied feedback to never appear",
            file: file,
            line: line
        )
    }

    func assertCopiedFeedbackEventuallyDisappears(
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            copyFeedbackElement().waitForNonExistence(timeout: timeout),
            "Expected copied feedback to eventually disappear",
            file: file,
            line: line
        )
    }

    // MARK: - Pinned icon

    func assertPinnedIconExists(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.descendants(matching: .any)["pinned-clip-icon"].waitForExistence(timeout: timeout),
            "Expected pinned clip icon",
            file: file,
            line: line
        )
    }

    func assertPinnedIconEventuallyDisappears(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.descendants(matching: .any)["pinned-clip-icon"].waitForNonExistence(timeout: timeout),
            "Expected pinned clip icon to eventually disappear",
            file: file,
            line: line
        )
    }

    func assertImagePinnedIconExists(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.descendants(matching: .any)[ClipboardFixture.ImageClipboard.Accessibility.pinnedIconIdentifier]
                .waitForExistence(timeout: timeout),
            "Expected pinned image clip icon",
            file: file,
            line: line
        )
    }

    func assertImagePinnedIconEventuallyDisappears(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.descendants(matching: .any)[ClipboardFixture.ImageClipboard.Accessibility.pinnedIconIdentifier]
                .waitForNonExistence(timeout: timeout),
            "Expected pinned image clip icon to eventually disappear",
            file: file,
            line: line
        )
    }

    // MARK: - Row order

    func assert(
        _ upper: XCUIElement,
        appearsAbove lower: XCUIElement,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                upper.exists && lower.exists && upper.frame.minY < lower.frame.minY
            },
            "Expected upper element to appear above lower element",
            file: file,
            line: line
        )
    }

    func assertRowOrder(
        _ leading: XCUIElement,
        appearsBefore trailing: XCUIElement,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assert(leading, appearsAbove: trailing, timeout: timeout, file: file, line: line)
    }

    func assertAppRunningWithoutCrash(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            app.state, .runningForeground,
            "Expected app to remain running in the foreground",
            file: file,
            line: line
        )
    }

    // MARK: - Clipboard monitor

    func clipboardMonitorObservationCount(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Int {
        let marker = app.descendants(matching: .any)["clipboard-monitor-observation-count"]
        XCTAssertTrue(marker.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected the content-free clipboard monitor observation probe",
                      file: file, line: line)
        let raw = marker.value as? String ?? marker.label
        guard let count = Int(raw) else {
            XCTFail("Clipboard monitor observation count must be an integer", file: file, line: line)
            return -1
        }
        return count
    }

    func waitForClipboardMonitorObservation(
        after priorCount: Int,
        disposition: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let countMarker = app.descendants(matching: .any)["clipboard-monitor-observation-count"]
        let dispositionMarker = app.descendants(matching: .any)["clipboard-monitor-last-disposition"]
        XCTAssertTrue(countMarker.waitForExistence(timeout: timeout),
                      "Expected the clipboard monitor count probe", file: file, line: line)
        XCTAssertTrue(dispositionMarker.waitForExistence(timeout: timeout),
                      "Expected the clipboard monitor disposition probe", file: file, line: line)
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                let raw = countMarker.value as? String ?? countMarker.label
                let disp = dispositionMarker.value as? String ?? dispositionMarker.label
                return (Int(raw) ?? -1) > priorCount && disp == disposition
            },
            "Expected the real clipboard monitor to report \(disposition) after count \(priorCount)",
            file: file,
            line: line
        )
    }

    // MARK: - Readiness marker

    enum ReadinessState {
        case absent, malformed, stale, error, ready
    }

    func readinessState(identifier: String) -> ReadinessState {
        let marker = app.descendants(matching: .any)[identifier]
        guard marker.exists else { return .absent }
        let raw = marker.value as? String ?? marker.label
        guard raw.isEmpty == false else { return .malformed }
        if raw.lowercased() == "error" { return .error }
        return .ready
    }

    // MARK: - Private helpers

    private func copyFeedbackElement() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: ClipboardFixture.ImageClipboard.Accessibility.copyFeedbackIdentifier)
            .firstMatch
    }

    private func markerValue(_ identifier: String) -> Int? {
        let marker = app.descendants(matching: .any)[identifier]
        guard marker.exists else { return nil }
        if let raw = marker.value as? String { return Int(raw) }
        return Int(marker.label)
    }

    private func markerStringValue(_ identifier: String) -> String? {
        let marker = app.descendants(matching: .any)[identifier]
        guard marker.exists else { return nil }
        return marker.value as? String ?? marker.label
    }

    private func datasetCounts() -> [Int]? {
        guard let raw = markerStringValue("history-visible-dataset-counts") else { return nil }
        let values = raw.split(separator: "|", omittingEmptySubsequences: false).compactMap { Int($0) }
        return values.count == 5 ? values : nil
    }

    private func assertMarkerValue(
        _ identifier: String,
        equals expected: Int,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) {
        guard UITestWait.until(timeout: timeout, condition: { markerValue(identifier) == expected }) == false else { return }
        XCTAssertEqual(markerValue(identifier), expected,
                       "Expected \(identifier) to equal \(expected)", file: file, line: line)
    }
}
