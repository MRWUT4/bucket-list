//
//  ActivityView.swift
//  bucket-list
//

import SwiftData
import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let item: BucketItem

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var activityItems: [Any] = []

        if let urlString = item.urlString, let url = URL(string: urlString) {
            activityItems.append(url)
        } else if let imageData = item.imageData, let image = UIImage(data: imageData) {
            activityItems.append(image)
        }

        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#if DEBUG
#Preview {
    ActivityView(item: PreviewSampleData.sampleBucketItem)
        .modelContainer(PreviewSampleData.container)
}
#endif
