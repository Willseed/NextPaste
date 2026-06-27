//
//  ImageDuplicateIdentityTests.swift
//  NextPasteTests
//
//  Created by Copilot on 2026/6/28.
//

import Foundation
import Testing
@testable import NextPaste

@Suite("Image duplicate identity")
struct ImageDuplicateIdentityTests {
    @Test("same decoded pixels and dimensions share identity despite metadata changes")
    func sameDecodedPixelsAndDimensionsShareIdentityDespiteMetadataChanges() throws {
        let fixtures = ImageTestFixtures.samePixelsDifferentMetadata

        let plainIdentity = try identity(for: fixtures.plainPNG)
        let metadataIdentity = try identity(for: fixtures.metadataPNG)

        #expect(fixtures.plainPNG.data != fixtures.metadataPNG.data)
        #expect(plainIdentity == metadataIdentity)
        #expect(plainIdentity.hash == metadataIdentity.hash)
        #expect(plainIdentity.hash.isEmpty == false)
        #expect(plainIdentity.width == fixtures.plainPNG.width)
        #expect(plainIdentity.height == fixtures.plainPNG.height)
    }

    @Test("distinct supported fixtures have distinct decoded-pixel dimension identities")
    func distinctSupportedFixturesHaveDistinctIdentities() throws {
        let identitiesByFixture = try ImageTestFixtures.supportedCaptureFixtures.map { fixture in
            (fixture: fixture, identity: try identity(for: fixture))
        }

        for leftIndex in identitiesByFixture.indices {
            for rightIndex in identitiesByFixture.indices where rightIndex > leftIndex {
                let left = identitiesByFixture[leftIndex]
                let right = identitiesByFixture[rightIndex]

                #expect(left.identity != right.identity)
                #expect(
                    left.identity.hash != right.identity.hash
                        || left.identity.width != right.identity.width
                        || left.identity.height != right.identity.height
                )
            }
        }
    }

    @Test("supported fixture hashes are stable non-empty and preserve dimensions")
    func supportedFixtureHashesAreStableNonEmptyAndPreserveDimensions() throws {
        let fixtures = ImageTestFixtures.supportedCaptureFixtures
            + ImageTestFixtures.samePixelsDifferentMetadata.fixtures

        for fixture in fixtures {
            let firstIdentity = try identity(for: fixture)
            let secondIdentity = try identity(for: fixture)

            #expect(firstIdentity == secondIdentity)
            #expect(firstIdentity.hash == secondIdentity.hash)
            #expect(firstIdentity.hash.isEmpty == false)
            #expect(firstIdentity.width == fixture.width)
            #expect(firstIdentity.height == fixture.height)
        }
    }

    private func identity(for fixture: ImageTestFixtures.ImageFixture) throws -> ImageDuplicateIdentity {
        try ImageDuplicateIdentity(encodedData: fixture.data)
    }
}
