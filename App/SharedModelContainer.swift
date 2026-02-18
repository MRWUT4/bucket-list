//
//  SharedModelContainer.swift
//  bucket-list
//

import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupIdentifier = "group.de.davidochmann.bucketlist"

    static var url: URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
            .appendingPathComponent("bucket-list.store")
    }

    static var container: ModelContainer {
        let schema = Schema([Bucket.self, BucketItem.self])
        let config = ModelConfiguration(url: url)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
