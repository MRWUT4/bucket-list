//
//  Bucket.swift
//  bucket-list
//

import Foundation
import SwiftData

@Model
final class Bucket {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \BucketItem.bucket)
    var items: [BucketItem]

    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.items = []
    }
}
