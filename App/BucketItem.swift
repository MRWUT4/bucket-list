//
//  BucketItem.swift
//  bucket-list
//

import Foundation
import SwiftData

@Model
final class BucketItem {
    var urlString: String
    var createdAt: Date
    var bucket: Bucket?

    var url: URL? {
        URL(string: urlString)
    }

    init(urlString: String, bucket: Bucket) {
        self.urlString = urlString
        self.createdAt = Date()
        self.bucket = bucket
    }
}
