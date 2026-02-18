//
//  BucketPickerView.swift
//  ShareExtension
//

import SwiftData
import SwiftUI

struct BucketPickerView: View {
    let content: SharedContent
    let onDismiss: () -> Void

    @State private var buckets: [Bucket] = []
    @State private var showingNewBucket = false
    @State private var newBucketName = ""
    private let container = SharedModelContainer.extensionContainer

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List(buckets) { bucket in
                    Button {
                        addItem(to: bucket)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(bucket.name)
                                .font(.headline)
                            Text("\((bucket.items ?? []).count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                FloatingActionButton {
                    showingNewBucket = true
                }
                .padding()
            }
            .navigationTitle("Save to Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .alert("New Bucket", isPresented: $showingNewBucket) {
                TextField("Name", text: $newBucketName)
                Button("Cancel", role: .cancel) { newBucketName = "" }
                Button("Add") {
                    createBucketAndAddItem()
                }
                .disabled(newBucketName.isEmpty)
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
    private func addItem(to bucket: Bucket) {
        let context = container.mainContext
        let item: BucketItem
        switch content {
        case .url(let url):
            item = BucketItem(urlString: url.absoluteString, bucket: bucket)
        case .image(let data):
            item = BucketItem(imageData: data, bucket: bucket)
        }
        context.insert(item)
        try? context.save()
        onDismiss()
    }

    @MainActor
    private func createBucketAndAddItem() {
        let context = container.mainContext
        let bucket = Bucket(name: newBucketName)
        context.insert(bucket)
        newBucketName = ""
        addItem(to: bucket)
    }
}
