//
//  BucketPickerView.swift
//  ShareExtension
//

import SwiftData
import SwiftUI

struct BucketPickerView: View {
    let url: URL
    let onDismiss: () -> Void

    @State private var buckets: [Bucket] = []
    private let container = SharedModelContainer.container

    var body: some View {
        NavigationStack {
            List(buckets) { bucket in
                Button {
                    addURL(to: bucket)
                } label: {
                    VStack(alignment: .leading) {
                        Text(bucket.name)
                            .font(.headline)
                        Text("\(bucket.items.count) links")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Save to Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
        .onAppear { loadBuckets() }
    }

    @MainActor
    private func loadBuckets() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Bucket>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        buckets = (try? context.fetch(descriptor)) ?? []
    }

    @MainActor
    private func addURL(to bucket: Bucket) {
        let context = container.mainContext
        let item = BucketItem(urlString: url.absoluteString, bucket: bucket)
        context.insert(item)
        try? context.save()
        onDismiss()
    }
}
