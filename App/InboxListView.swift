//
//  InboxListView.swift
//  bucket-list
//
//  Created by Ochmann, David on 17.02.26.
//

import SwiftData
import SwiftUI

struct InboxListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bucket.createdAt, order: .reverse) private var buckets: [Bucket]

    @State private var showingAddBucket = false
    @State private var newBucketName = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(buckets) { bucket in
                        NavigationLink(value: bucket) {
                            VStack(alignment: .leading) {
                                Text(bucket.name)
                                    .font(.headline)
                                Text("\(bucket.items.count) links")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteBuckets)
                }
                .navigationTitle("Buckets")
                .navigationDestination(for: Bucket.self) { bucket in
                    BucketListView(bucket: bucket)
                }

                FloatingActionButton {
                    showingAddBucket = true
                }
                .padding()
            }
            .alert("New Bucket", isPresented: $showingAddBucket) {
                TextField("Name", text: $newBucketName)
                Button("Cancel", role: .cancel) { newBucketName = "" }
                Button("Add") {
                    let bucket = Bucket(name: newBucketName)
                    modelContext.insert(bucket)
                    newBucketName = ""
                }
                .disabled(newBucketName.isEmpty)
            }
        }
    }

    private func deleteBuckets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(buckets[index])
        }
    }
}
