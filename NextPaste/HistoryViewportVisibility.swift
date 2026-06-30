//
//  HistoryViewportVisibility.swift
//  NextPaste
//

import CoreGraphics
import Foundation

enum HistoryViewportVisibility {
    enum CorrectiveScrollDecision: Equatable {
        case unavailable
        case notNeeded
        case scroll(UUID)
    }

    struct Plan: Equatable {
        let topInset: CGFloat
        let visibleBoundary: CGFloat
        let firstVisibleRowID: UUID?
        let correctiveScrollDecision: CorrectiveScrollDecision
    }

    static func pendingInsertedFirstVisibleRowID(
        previousVisibleIDs: [UUID],
        currentVisibleIDs: [UUID]
    ) -> UUID? {
        guard previousVisibleIDs.isEmpty == false,
              let currentFirstVisibleID = currentVisibleIDs.first else {
            return nil
        }

        let previousVisibleIDSet = Set(previousVisibleIDs)
        let insertedVisibleIDs = Set(currentVisibleIDs.filter { previousVisibleIDSet.contains($0) == false })

        guard insertedVisibleIDs.contains(currentFirstVisibleID) else {
            return nil
        }

        return currentFirstVisibleID
    }

    static func makePlan(
        candidateRowID: UUID?,
        rowFrames: [UUID: CGRect],
        viewportFrame: CGRect,
        fixedHeaderBottom: CGFloat,
        minimumTopInset: CGFloat
    ) -> Plan {
        let hasValidViewport = isValid(frame: viewportFrame)
        let topInset = measuredTopInset(
            viewportMinY: viewportFrame.minY,
            fixedHeaderBottom: fixedHeaderBottom,
            minimumTopInset: minimumTopInset
        )
        let visibleBoundary = hasValidViewport ? max(viewportFrame.minY, fixedHeaderBottom) : fixedHeaderBottom
        let firstVisibleRowID = firstVisibleRowID(
            rowFrames: rowFrames,
            visibleBoundary: visibleBoundary,
            viewportMaxY: viewportFrame.maxY
        )

        guard let candidateRowID else {
            return Plan(
                topInset: topInset,
                visibleBoundary: visibleBoundary,
                firstVisibleRowID: firstVisibleRowID,
                correctiveScrollDecision: .notNeeded
            )
        }

        guard hasValidViewport,
              let candidateFrame = rowFrames[candidateRowID] else {
            return Plan(
                topInset: topInset,
                visibleBoundary: visibleBoundary,
                firstVisibleRowID: firstVisibleRowID,
                correctiveScrollDecision: .unavailable
            )
        }

        let decision: CorrectiveScrollDecision = isFullyVisible(
            rowFrame: candidateFrame,
            viewportFrame: viewportFrame,
            visibleBoundary: visibleBoundary
        ) ? .notNeeded : .scroll(candidateRowID)

        return Plan(
            topInset: topInset,
            visibleBoundary: visibleBoundary,
            firstVisibleRowID: firstVisibleRowID,
            correctiveScrollDecision: decision
        )
    }

    static func measuredTopInset(
        viewportMinY: CGFloat,
        fixedHeaderBottom: CGFloat,
        minimumTopInset: CGFloat
    ) -> CGFloat {
        guard viewportMinY.isFinite, fixedHeaderBottom.isFinite else {
            return minimumTopInset
        }

        return max(minimumTopInset, fixedHeaderBottom - viewportMinY + minimumTopInset)
    }

    static func firstVisibleRowID(
        rowFrames: [UUID: CGRect],
        visibleBoundary: CGFloat,
        viewportMaxY: CGFloat
    ) -> UUID? {
        rowFrames
            .filter { id, frame in
                _ = id
                return frame.maxY > visibleBoundary && frame.minY < viewportMaxY
            }
            .min { lhs, rhs in
                lhs.value.minY < rhs.value.minY
            }?
            .key
    }

    static func isFullyVisible(
        rowFrame: CGRect,
        viewportFrame: CGRect,
        visibleBoundary: CGFloat
    ) -> Bool {
        guard isValid(frame: rowFrame), isValid(frame: viewportFrame) else {
            return false
        }

        return rowFrame.minY >= visibleBoundary && rowFrame.maxY <= viewportFrame.maxY
    }

    private static func isValid(frame: CGRect) -> Bool {
        frame.isNull == false &&
            frame.isEmpty == false &&
            frame.minY.isFinite &&
            frame.maxY.isFinite &&
            frame.width.isFinite &&
            frame.height.isFinite
    }
}
