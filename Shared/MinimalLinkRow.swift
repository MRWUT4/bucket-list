//
//  MinimalLinkRow.swift
//  bucket-list
//

import LinkPresentation
import SwiftUI
import UIKit

struct MinimalLinkRow: View {
    let url: URL
    let savedAt: Date

    static let imageHeight: CGFloat = 180
    static let textBlockHeight: CGFloat = 88

    @State private var isLoading = true
    @State private var fetchedTitle: String?
    @State private var previewImage: UIImage?

    private var domain: String {
        (url.host ?? url.absoluteString)
            .replacingOccurrences(of: "www.", with: "")
    }

    private var savedLabel: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return "saved " + f.localizedString(for: savedAt, relativeTo: .now)
    }

    private var displayTitle: String {
        fetchedTitle ?? url.absoluteString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                skeletonView
            } else if let previewImage {
                loadedView(image: previewImage)
            } else {
                loadedViewNoImage
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .task(id: url) {
            guard isLoading else { return }
            let provider = LPMetadataProvider()
            let metadata = try? await provider.startFetchingMetadata(for: url)

            if let title = metadata?.title, !title.isEmpty {
                fetchedTitle = title
            }

            if let imageProvider = metadata?.imageProvider,
               let image = await Self.loadImage(from: imageProvider) {
                previewImage = image
            }

            isLoading = false
        }
    }

    // MARK: - Loaded states

    private func loadedView(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: Self.imageHeight)
                .clipped()

            textBlock
        }
    }

    private var loadedViewNoImage: some View {
        textBlock
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(domain)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(displayTitle)
                .font(.system(size: 19, weight: .medium))
                .tracking(-0.35)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(.top, 2)

            Text(savedLabel)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, MinimalDesign.horizontalMargin)
    }

    // MARK: - Skeleton

    private var skeletonView: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.secondary.opacity(0.08))
                .frame(maxWidth: .infinity)
                .frame(height: Self.imageHeight)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 80, height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
                    .padding(.top, 2)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 160, height: 18)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 70, height: 12)
                    .padding(.top, 2)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, MinimalDesign.horizontalMargin)
        }
    }

    private static func loadImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object as? UIImage)
            }
        }
    }
}

struct MinimalImageRow: View {
    let imageData: Data
    let savedAt: Date

    private var savedLabel: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return "saved " + f.localizedString(for: savedAt, relativeTo: .now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Image")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(savedLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, MinimalDesign.horizontalMargin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview("Link Row") {
    List {
        MinimalLinkRow(url: URL(string: "https://apple.com")!, savedAt: .now.addingTimeInterval(-3600))
            .listRowBackground(MinimalDesign.warmBg)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(MinimalDesign.warmBg)
}

#Preview("Image Row") {
    List {
        MinimalImageRow(imageData: PreviewSampleData.sampleImageData, savedAt: .now.addingTimeInterval(-7200))
            .listRowBackground(MinimalDesign.warmBg)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(MinimalDesign.warmBg)
}
#endif
