//
//  SharedModelContainer.swift
//  bucket-list
//

import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupIdentifier = "group.de.davidochmann.bucketlist"
    static let cloudKitContainerIdentifier = "iCloud.de.davidochmann.bucketlist"

    static var storeURL: URL {
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        let baseURL = groupURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return baseURL.appendingPathComponent("BucketList.store")
    }

    static let container: ModelContainer = {
        let schema = Schema([Bucket.self, BucketItem.self])
        do {
            let config = ModelConfiguration(
                "BucketList",
                url: storeURL,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            do {
                let config = ModelConfiguration("BucketList", url: storeURL)
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }()
}
