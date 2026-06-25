//
//  SwiftDataTestSupport.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import SwiftData

enum SwiftDataTestSupport {
    static func makeInMemoryContainer(for schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}