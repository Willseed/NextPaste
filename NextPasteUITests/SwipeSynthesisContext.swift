//
//  SwipeSynthesisContext.swift
//  NextPasteUITests
//

import XCTest

internal struct SwipeSynthesisContext {
    enum Direction {
        case right
        case left
    }

    let gestureCandidates: [XCUIElement]
    let targetedRow: XCUIElement
    let actionButtonIdentifier: String
    let expectedAccessibleLabel: String
    let direction: Direction
    let application: XCUIApplication
}
