//
//  BucketListView.swift
//  bucket-list
//

import SwiftData
import SwiftUI
import UIKit

enum BucketFilter: String, CaseIterable {
    case all
    case links
    case images

    var label: String {
        switch self {
        case .all: return "All"
        case .links: return "Links"
        case .images: return "Images"
        }
    }
}

enum BucketSortOrder: String, CaseIterable {
    case chronological
    case alphabetical

    var iconName: String {
        switch self {
        case .chronological: return "clock"
        case .alphabetical: return "textformat"
        }
    }

    var label: String {
        switch self {
        case .chronological: return "Chronological"
        case .alphabetical: return "Alphabetical"
        }
    }
}

struct BucketListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \Bucket.createdAt, order: .reverse) private var allBuckets: [Bucket]
    let bucket: Bucket

    @State private var showingAddURL = false
    @State private var showingRename = false
    @State private var showingCustomize = false
    @State private var newName = ""
    @State private var selectedImageData: Data?
    @State private var shareItem: BucketItem?
    @State private var moveItem: BucketItem?
    @AppStorage("bucketSortOrder") private var sortOrder: BucketSortOrder = .chronological
    @State private var filter: BucketFilter = .all

    var sortedItems: [BucketItem] {
        let items = bucket.items ?? []
        let filtered: [BucketItem]
        switch filter {
        case .all:    filtered = items
        case .links:  filtered = items.filter { !$0.isImage }
        case .images: filtered = items.filter { $0.isImage }
        }
        switch sortOrder {
        case .chronological:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return filtered.sorted { itemTitle($0) < itemTitle($1) }
        }
    }

    private func itemTitle(_ item: BucketItem) -> String {
        if item.isImage {
            return "Image"
        } else if let urlString = item.urlString {
            return urlString.lowercased()
        }
        return ""
    }

    private var heroMeta: String {
        let n = sortedItems.count
        switch filter {
        case .all:    return "\(n) \(n == 1 ? "item" : "items")"
        case .links:  return "\(n) \(n == 1 ? "link" : "links")"
        case .images: return "\(n) \(n == 1 ? "image" : "images")"
        }
    }

    var body: some View {
        List {
            heroRow

            ForEach(sortedItems) { item in
                Group {
                    if item.isImage, let imageData = item.imageData {
                        MinimalImageRow(imageData: imageData, savedAt: item.createdAt)
                            .onTapGesture { selectedImageData = imageData }
                    } else if let url = item.url {
                        MinimalLinkRow(url: url, savedAt: item.createdAt)
                            .onTapGesture { openURL(url) }
                    }
                }
                .padding(.bottom)
                .listRowBackground(MinimalDesign.warmBg)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .swipeActions(edge: .leading) {
                    Button {
                        shareItem = item
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)

                    Button {
                        moveItem = item
                    } label: {
                        Label("Move", systemImage: "folder")
                    }
                    .tint(.orange)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(MinimalDesign.warmBg)
        .navigationTitle(bucket.name)
        .onChange(of: hasMixedContent) {
            if !hasMixedContent { filter = .all }
        }
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
                Menu {
                    Button {
                        newName = bucket.name
                        showingRename = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        showingCustomize = true
                    } label: {
                        Label("Customize", systemImage: "paintpalette")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .alert("Rename Bucket", isPresented: $showingRename) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                bucket.name = newName
            }
            .disabled(newName.isEmpty)
        }
        .sheet(isPresented: $showingCustomize) {
            BucketCustomizeSheet(bucket: bucket)
        }
        .sheet(isPresented: $showingAddURL) {
            AddURLSheet { urlString in
                let item = BucketItem(urlString: urlString, bucket: bucket)
                modelContext.insert(item)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedImageData != nil },
            set: { if !$0 { selectedImageData = nil } }
        )) {
            if let imageData = selectedImageData {
                FullScreenImageView(imageData: imageData)
            }
        }
        .sheet(isPresented: Binding(
            get: { shareItem != nil },
            set: { if !$0 { shareItem = nil } }
        )) {
            if let item = shareItem {
                ActivityView(item: item)
            }
        }
        .sheet(isPresented: Binding(
            get: { moveItem != nil },
            set: { if !$0 { moveItem = nil } }
        )) {
            if let item = moveItem {
                MoveToBucketSheet(
                    item: item,
                    buckets: allBuckets.filter { $0.persistentModelID != bucket.persistentModelID }
                ) { destination in
                    item.bucket = destination
                    moveItem = nil
                }
            }
        }
    }

    private var hasMixedContent: Bool {
        let items = bucket.items ?? []
        let hasLinks = items.contains { !$0.isImage }
        let hasImages = items.contains { $0.isImage }
        return hasLinks && hasImages
    }

    private var heroRow: some View {
        let tint = MinimalDesign.resolvedTint(for: bucket.name, customIndex: bucket.customColorIndex)
        let symbol = MinimalDesign.resolvedSymbol(for: bucket.name, customIndex: bucket.customSymbolIndex)

        return VStack(alignment: .leading, spacing: 10) {
//            HStack(spacing: 10) {
//                Image(systemName: symbol)
//                    .font(.system(size: 20, weight: .regular))
//                    .foregroundStyle(tint)
            Text(heroMeta)
                .kickerStyle(symbol: symbol, tint: tint)
//                .border(.red)
//            }
//            .edgeInsets(for: .)
//            Text("\(bucket.name).")
//                .displayTitle(size: 40)
//                .foregroundStyle(.primary)
//                .lineLimit(2)
//                .multilineTextAlignment(.leading)

            if hasMixedContent {
                HStack(spacing: 18) {
                    ForEach(BucketFilter.allCases, id: \.self) { tab in
                        filterTab(tab.label, active: filter == tab)
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { filter = tab } }
                    }
                    Spacer()
                }
//                .border(.red)
                .padding(.top, 14)
            }

//            Rectangle()
//                .fill(Color.secondary.opacity(0.25))
//                .frame(height: 0.5)
//                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MinimalDesign.horizontalMargin)
//        .padding(.top, 16)
        .padding(.bottom, 8)
        .listRowBackground(MinimalDesign.warmBg)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: 0))
        .selectionDisabled()
    }

    private func filterTab(_ label: String, active: Bool) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: active ? .semibold : .regular))
                .tracking(-0.15)
                .foregroundStyle(active ? Color.primary : Color.secondary)
            Rectangle()
                .fill(active ? Color.primary : Color.clear)
                .frame(height: 1.5)
                .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedItems[index])
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        BucketListView(bucket: PreviewSampleData.sampleBucket)
    }
    .modelContainer(PreviewSampleData.container)
}
#endif
