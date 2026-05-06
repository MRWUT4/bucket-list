//
//  MoveToBucketSheet.swift
//  bucket-list
//

import SwiftUI

struct MoveToBucketSheet: View {
    let item: BucketItem
    let buckets: [Bucket]
    let onMove: (Bucket) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(buckets) { bucket in
                    Button {
                        onMove(bucket)
                        dismiss()
                    } label: {
                        let tint = MinimalDesign.resolvedTint(for: bucket.name, customIndex: bucket.customColorIndex)
                        let symbol = MinimalDesign.resolvedSymbol(for: bucket.name, customIndex: bucket.customSymbolIndex)
                        HStack(spacing: 14) {
                            Image(systemName: symbol)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(tint)
                                .frame(width: 22, alignment: .center)

                            Text(bucket.name)
                                .font(.system(size: 17))
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(MinimalDesign.warmBg)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MinimalDesign.warmBg)
            .navigationTitle("Move to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
