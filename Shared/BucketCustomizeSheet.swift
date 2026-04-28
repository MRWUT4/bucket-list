//
//  BucketCustomizeSheet.swift
//  bucket-list
//

import SwiftUI

struct BucketCustomizeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let bucket: Bucket

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 6)
    private let symbolColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    private var selectedColorIndex: Int {
        if bucket.customColorIndex >= 0 {
            return bucket.customColorIndex
        }
        return MinimalDesign.tintColors.firstIndex(of: MinimalDesign.tint(for: bucket.name)) ?? -1
    }

    private var selectedSymbolIndex: Int {
        if bucket.customSymbolIndex >= 0 {
            return bucket.customSymbolIndex
        }
        return MinimalDesign.tintSymbols.firstIndex(of: MinimalDesign.symbol(for: bucket.name)) ?? -1
    }

    private var resolvedTint: Color {
        MinimalDesign.resolvedTint(for: bucket.name, customIndex: bucket.customColorIndex)
    }

    private var resolvedSymbol: String {
        MinimalDesign.resolvedSymbol(for: bucket.name, customIndex: bucket.customSymbolIndex)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Live preview
                    VStack(spacing: 8) {
                        Image(systemName: resolvedSymbol)
                            .font(.system(size: 40, weight: .regular))
                            .foregroundStyle(resolvedTint)
                            .frame(height: 50)
                            .animation(.easeInOut(duration: 0.2), value: resolvedSymbol)
                            .animation(.easeInOut(duration: 0.2), value: bucket.customColorIndex)
                        Text(bucket.name)
                            .font(.system(size: 17, weight: .medium))
                            .tracking(-0.3)
                    }
                    .padding(.top, 8)

                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .kickerStyle()
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: colorColumns, spacing: 14) {
                            ForEach(Array(MinimalDesign.tintColors.enumerated()), id: \.offset) { index, color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if index == selectedColorIndex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture {
                                        bucket.customColorIndex = index
                                    }
                            }
                        }
                    }

                    // Symbol picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Symbol")
                            .kickerStyle()
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: symbolColumns, spacing: 16) {
                            ForEach(Array(MinimalDesign.tintSymbols.enumerated()), id: \.offset) { index, symbol in
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundStyle(index == selectedSymbolIndex ? resolvedTint : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(index == selectedSymbolIndex
                                                  ? resolvedTint.opacity(0.12)
                                                  : Color.clear)
                                    )
                                    .onTapGesture {
                                        bucket.customSymbolIndex = index
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, MinimalDesign.horizontalMargin)
                .padding(.bottom, 24)
            }
            .background(MinimalDesign.warmBg)
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
