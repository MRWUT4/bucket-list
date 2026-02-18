//
//  BucketItem.swift
//  bucket-list
//

import Foundation
import SwiftData

@Model
final class BucketItem {
    var urlString: String?
    var imageData: Data?
    var createdAt: Date = Date()
    var bucket: Bucket?

    var url: URL? {
        guard let urlString else { return nil }
        return URL(string: urlString)
    }

    var isImage: Bool {
        imageData != nil
    }

    init(urlString: String, bucket: Bucket) {
        self.urlString = urlString
        self.imageData = nil
        self.createdAt = Date()
        self.bucket = bucket
    }

    init(imageData: Data, bucket: Bucket) {
        self.urlString = nil
        self.imageData = imageData
        self.createdAt = Date()
        self.bucket = bucket
    }
}
