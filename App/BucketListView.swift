//
//  BucketListView.swift
//  bucket-list
//

import SwiftData
import SwiftUI
import UIKit

struct BucketListView: View {
    @Environment(\.modelContext) private var modelContext
    let bucket: Bucket

    @State private var showingAddURL = false
    @State private var showingRename = false
    @State private var newName = ""
    @State private var selectedImageData: Data?
    @State private var shareItem: BucketItem?

    var sortedItems: [BucketItem] {
        (bucket.items ?? []).sorted { $0.createdAt > $1.createdAt }
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
                            LinkPreviewView(url: url)
                                .frame(minHeight: 120)
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
