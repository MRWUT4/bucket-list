//
//  PreviewSampleData.swift
//  bucket-list
//

#if DEBUG

import SwiftData
import UIKit

enum PreviewSampleData {
    static let container: ModelContainer = {
        let schema = Schema([Bucket.self, BucketItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        let context = container.mainContext

        let tech = Bucket(name: "Tech")
        context.insert(tech)
        context.insert(BucketItem(urlString: "https://apple.com", bucket: tech))
        context.insert(BucketItem(urlString: "https://github.com", bucket: tech))

        let design = Bucket(name: "Design")
        context.insert(design)
        context.insert(BucketItem(urlString: "https://dribbble.com", bucket: design))

        let news = Bucket(name: "News")
        context.insert(news)

        let images = Bucket(name: "Images")
        context.insert(images)
        context.insert(BucketItem(imageData: sampleImageData, bucket: images))

        return container
    }()

    static let sampleImageData: Data = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        return renderer.jpegData(withCompressionQuality: 0.8) { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        }
    }()

    static var sampleBucket: Bucket {
        try! container.mainContext.fetch(FetchDescriptor<Bucket>()).first!
    }

    static var sampleBucketItem: BucketItem {
        try! container.mainContext.fetch(FetchDescriptor<BucketItem>()).first!
    }
}

#endif
