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

    var onBucketTapped: ((Bucket) -> Void)?

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

    private var totalLinks: Int {
        buckets.reduce(0) { $0 + ($1.items?.count ?? 0) }
    }

    private var heroTitle: String {
        onBucketTapped != nil ? "Save to." : "Buckets."
    }

    private var heroKicker: String {
        onBucketTapped != nil ? "Share Extension" : "Your library"
    }

    private var heroMeta: String? {
        guard onBucketTapped == nil else { return nil }
        let bucketCount = buckets.count
        return "\(bucketCount) \(bucketCount == 1 ? "bucket" : "buckets") · \(totalLinks) \(totalLinks == 1 ? "link" : "links")"
    }

    var body: some View {
        if onBucketTapped != nil {
            bucketListContent
        } else {
            NavigationSplitView {
                bucketListContent
                    .refreshable {
                        await triggerCloudKitSync()
                    }
            } detail: {
                if let selectedBucket {
                    BucketListView(bucket: selectedBucket)
                } else {
                    ContentUnavailableView("Select a Bucket", systemImage: "folder", description: Text("Choose a bucket from the sidebar"))
                }
            }
        }
    }

    private var bucketListContent: some View {
        Group {
            let edgeInset = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            
            if let onBucketTapped {
                List {
                    heroRow
                    ForEach(sortedBuckets) { bucket in
                        Button {
                            onBucketTapped(bucket)
                        } label: {
                            bucketRow(bucket)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(MinimalDesign.warmBg)
                        .listRowSeparator(.hidden)
                        .listRowInsets(edgeInset)
                    }
                    .onDelete(perform: deleteBuckets)
                }
            } else {
                List(selection: $selectedBucket) {
                    heroRow
                    ForEach(sortedBuckets) { bucket in
                        NavigationLink(value: bucket) {
                            bucketRow(bucket)
                        }
                        .listRowBackground(MinimalDesign.warmBg)
                        .listRowSeparator(.hidden)
                        .listRowInsets(edgeInset)
                    }
                    .onDelete(perform: deleteBuckets)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(MinimalDesign.warmBg)
        .navigationTitle(onBucketTapped != nil ? "Save to Bucket" : "Buckets")
//        .navigationBarTitleDisplayMode(.inline)
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

    private var heroRow: some View {
//        MinimalHeroHeader(
//            kicker: heroKicker,
//            title: heroTitle,
//            meta: heroMeta
//        )
        Text(heroMeta ?? "")
            .kickerStyle()
            .listRowBackground(MinimalDesign.warmBg)
            .listRowSeparator(.hidden)
//            .listRowInsets(EdgeInsets(top: -32, leading: -8, bottom: 0, trailing: 0))
            .selectionDisabled()
    }

    private func bucketRow(_ bucket: Bucket) -> some View {
        let tint = MinimalDesign.resolvedTint(for: bucket.name, customIndex: bucket.customColorIndex)
        let symbol = MinimalDesign.resolvedSymbol(for: bucket.name, customIndex: bucket.customSymbolIndex)
        let count = bucket.items?.count ?? 0
        return HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 22, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(bucket.name)
                    .font(.system(size: 20, weight: .regular))
                    .tracking(-0.4)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(count) \(count == 1 ? "link" : "links") · added \(relativeDate(bucket.createdAt))")
                    .font(.system(size: 13))
                    .fontWeight(.light)
                    .foregroundStyle(.secondary)
                //                .foregroundStyle(count > 0 ? MinimalDesign.accent : Color.secondary.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()
//            Spacer(minLength: 8)

//            Text(count > 0 ? "\(count)" : "—")
//                .font(.system(size: 15, weight: count > 0 ? .semibold : .regular))
//                .monospacedDigit()
//                .foregroundStyle(count > 0 ? MinimalDesign.accent : Color.secondary.opacity(0.6))
////                .padding(.trailing)
        }
//        .padding(.horizontal, MinimalDesign.horizontalMargin)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: .now)
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

#if DEBUG
#Preview("App") {
    InboxListView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("Share Extension") {
    NavigationStack {
        InboxListView(onBucketTapped: { _ in })
    }
    .modelContainer(PreviewSampleData.container)
}
#endif
