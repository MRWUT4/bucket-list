//
//  InboxListView.swift
//  bucket-list
//
//  Created by Ochmann, David on 17.02.26.
//

import CloudKit
import SwiftData
import SwiftUI

struct InboxListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bucket.createdAt, order: .reverse) private var buckets: [Bucket]

    @State private var showingAddBucket = false
    @State private var newBucketName = ""
    @State private var selectedBucket: Bucket?
    @AppStorage("inboxSortOrder") private var sortOrder: BucketSortOrder = .chronological

    var sortedBuckets: [Bucket] {
        switch sortOrder {
        case .chronological:
            return buckets.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return buckets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationSplitView {
                List(selection: $selectedBucket) {
                    ForEach(sortedBuckets) { bucket in
                        NavigationLink(value: bucket) {
                            VStack(alignment: .leading) {
                                Text(bucket.name)
                                    .font(.headline)
                                Text("\((bucket.items ?? []).count) links")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteBuckets)
                }
                .navigationTitle("Buckets")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            ForEach(BucketSortOrder.allCases, id: \.self) { order in
                                Button {
                                    sortOrder = order
                                } label: {
                                    Label(order.label, systemImage: order.iconName)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: sortOrder.iconName)
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddBucket = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.accent)
                        }
                    }
                }
                .refreshable {
                    await triggerCloudKitSync()
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
        } detail: {
            if let selectedBucket {
                BucketListView(bucket: selectedBucket)
            } else {
                ContentUnavailableView("Select a Bucket", systemImage: "folder", description: Text("Choose a bucket from the sidebar"))
            }
        }
    }

    private func deleteBuckets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedBuckets[index])
        }
    }

    private func triggerCloudKitSync() async {
        try? modelContext.save()

        let container = CKContainer(identifier: SharedModelContainer.cloudKitContainerIdentifier)
        do {
            _ = try await container.privateCloudDatabase.allRecordZones()
        } catch {
            // CloudKit sync will eventually happen on its own
        }
    }
}
