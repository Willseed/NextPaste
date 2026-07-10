//
//  ClipDatasetIntegritySnapshot.swift
//  NextPaste
//

import CryptoKit
import Foundation

/// Content-free digest used only by UI tests to compare a persisted dataset
/// across relaunch. The digest contains no clipboard text or image payload.
enum ClipDatasetIntegritySnapshot {
    static func digest(for clips: [ClipItem]) -> String {
        let canonicalRows = clips
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { clip in
                [
                    clip.id.uuidString,
                    clip.contentType,
                    SHA256.hash(data: Data(clip.textContent.utf8)).hexString,
                    clip.imageHash ?? "",
                    "\(clip.imageWidth ?? 0)",
                    "\(clip.imageHeight ?? 0)",
                    "\(clip.imageByteCount ?? 0)",
                    clip.imageUTType ?? "",
                    clip.imageFilename ?? "",
                    clip.thumbnailFilename ?? "",
                    clip.isPinned ? "1" : "0",
                    "\(clip.pinnedSortOrder)",
                    "\(clip.createdAt.timeIntervalSince1970)",
                    "\(clip.updatedAt.timeIntervalSince1970)",
                    clip.sectionSortDate.map { "\($0.timeIntervalSince1970)" } ?? ""
                ].joined(separator: "|")
            }
            .joined(separator: "\n")
        return SHA256.hash(data: Data(canonicalRows.utf8)).hexString
    }
}

private extension SHA256.Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
