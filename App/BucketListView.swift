//
//  BucketListView.swift
//  bucket-list
//

import SwiftData
import SwiftUI
import UIKit

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
    let bucket: Bucket

    @State private var showingAddURL = false
    @State private var showingRename = false
    @State private var newName = ""
    @State private var selectedImageData: Data?
    @State private var shareItem: BucketItem?
    @AppStorage("bucketSortOrder") private var sortOrder: BucketSortOrder = .chronological

    var sortedItems: [BucketItem] {
        let items = bucket.items ?? []
        switch sortOrder {
        case .chronological:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return items.sorted { itemTitle($0) < itemTitle($1) }
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                ForEach(sortedItems) { item in
                    Group {
                        if item.isImage, let imageData = item.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    selectedImageData = imageData
                                }
                        } else if let url = item.url {
                            VStack(alignment: .leading, spacing: 4) {
                                LinkPreviewView(url: url)
                                    .frame(minHeight: 120)
                                Text(url.absoluteString)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            shareItem = item
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete(perform: deleteItems)
                .listRowSeparator(.hidden)
//                .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)

            FloatingActionButton {
                showingAddURL = true
            }
            .padding()
        }
        .navigationTitle(bucket.name)
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
                } label: {
                    Image(systemName: "ellipsis.circle")
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
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedItems[index])
        }
    }
}
