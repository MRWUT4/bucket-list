//
//  Bucket.swift
//  bucket-list
//

import Foundation
import SwiftData

@Model
final class Bucket {
    var name: String = ""
    var createdAt: Date = Date()
    var customColorIndex: Int = -1
    var customSymbolIndex: Int = -1
    @Relationship(deleteRule: .cascade, inverse: \BucketItem.bucket)
    var items: [BucketItem]?

    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.customColorIndex = -1
        self.customSymbolIndex = -1
        self.items = []
    }
}
