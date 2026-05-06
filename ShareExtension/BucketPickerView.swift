//
//  BucketPickerView.swift
//  ShareExtension
//

import FoundationModels
import LinkPresentation
import SwiftData
import SwiftUI

@Generable
struct BucketSuggestion {
    @Guide(description: "The exact name of the bucket to save the item to")
    var bucketName: String

    @Guide(description: "true if bucketName is an existing bucket, false if new")
    var isExistingBucket: Bool

    @Guide(description: "A brief friendly one-sentence explanation of the decision")
    var explanation: String
}

struct BucketPickerView: View {
    let content: SharedContent
    let onDismiss: () -> Void

    @State private var suggestionState: BucketSuggestionState = .loading
    @State private var suggestedBucket: Bucket?
    private let container = SharedModelContainer.extensionContainer

    var body: some View {
        NavigationStack {
            InboxListView(
                onBucketTapped: { bucket in
                    saveItem(to: bucket)
                    onDismiss()
                }
            ) {
                suggestionRow
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
        .modelContainer(container)
        .task {
            await computeSuggestion()
        }
    }

    @ViewBuilder
    private var suggestionRow: some View {
        switch suggestionState {
        case .loading:
            HStack(alignment: .center, spacing: 14) {
                ProgressView()
                    .frame(width: 22, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Suggested")
                        .font(.system(size: 20, weight: .regular))
                        .tracking(-0.4)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("Analyzing…")
                        .font(.system(size: 13))
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

        case .loaded(let suggested, _):
            Button {
                if let bucket = suggestedBucket {
                    saveItem(to: bucket)
                    onDismiss()
                }
            } label: {
                let tint = MinimalDesign.resolvedTint(for: suggested.name, customIndex: suggested.customColorIndex)
                let symbol = MinimalDesign.resolvedSymbol(for: suggested.name, customIndex: suggested.customSymbolIndex)
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(tint)
                        .frame(width: 22, alignment: .center)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(suggested.name)
                            .font(.system(size: 20, weight: .regular))
                            .tracking(-0.4)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text("Suggested")
                            .font(.system(size: 13))
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(.purple)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

        case .failed:
            EmptyView()
        }
    }

    // MARK: - Data Operations

    @MainActor
    private func saveItem(to bucket: Bucket) {
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
    }

    // MARK: - Auto-Sort

    private func computeSuggestion() async {
        suggestionState = .loading
        switch content {
        case .url(let url):
            await computeURLSuggestion(url)
        case .image:
            computeImageSuggestion()
        }
    }

    private func fetchBuckets() -> [Bucket] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Bucket>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private func computeURLSuggestion(_ url: URL) async {
        let provider = LPMetadataProvider()
        let metadata = try? await provider.startFetchingMetadata(for: url)

        if SystemLanguageModel.default.isAvailable {
            do {
                try await smartSuggest(url: url, metadata: metadata)
            } catch {
                domainMatchSuggestion(url: url, metadata: metadata)
            }
        } else {
            domainMatchSuggestion(url: url, metadata: metadata)
        }
    }

    private func smartSuggest(url: URL, metadata: LPLinkMetadata?) async throws {
        let buckets = fetchBuckets()
        let instructions = """
            You are a smart organizer that categorizes web links into topic buckets.
            Suggest a new bucket if no existing one fits well.
            New buckets should follow the pattern: "Domain / Category". 
            """
        let session = LanguageModelSession(instructions: instructions)
        let prompt = buildSortPrompt(url: url, metadata: metadata, buckets: buckets)
        let response = try await session.respond(to: prompt, generating: BucketSuggestion.self)
        let suggestion = response.content

        if suggestion.isExistingBucket,
           let bucket = buckets.first(where: { $0.name == suggestion.bucketName }) {
            setSuggestion(bucket: bucket, explanation: suggestion.explanation)
        } else {
            let context = container.mainContext
            let bucket = Bucket(name: suggestion.bucketName)
            context.insert(bucket)
            setSuggestion(bucket: bucket, explanation: suggestion.explanation)
        }
    }

    private func buildSortPrompt(url: URL, metadata: LPLinkMetadata?, buckets: [Bucket]) -> String {
        let domain = url.host ?? url.absoluteString
        let title = metadata?.title ?? "Unknown"

        var prompt = """
            Categorize this link into a bucket.

            Link: \(url.absoluteString)
            Title: \(title)
            Domain: \(domain)

            """

        if buckets.isEmpty {
            prompt += "No existing buckets. Suggest a short, descriptive name for a new bucket."
        } else {
            prompt += "Existing buckets:\n"
            for bucket in buckets {
                let items = bucket.items ?? []
                let domains = items.compactMap { $0.url?.host }.prefix(5)
                let desc = domains.isEmpty
                    ? "\(items.count) items"
                    : "domains: \(domains.joined(separator: ", "))"
                prompt += "- \"\(bucket.name)\" (\(desc))\n"
            }
            prompt += "\nChoose an existing bucket if the link fits, or suggest a new name if none match."
        }

        return prompt
    }

    // MARK: - Fallbacks

    private func domainMatchSuggestion(url: URL, metadata: LPLinkMetadata?) {
        let buckets = fetchBuckets()
        let domain = url.host ?? url.absoluteString

        if let matchingBucket = findBestMatchingBucket(for: url, in: buckets) {
            setSuggestion(bucket: matchingBucket, explanation: "Matches other items from \(domain)")
        } else {
            let bucketName = metadata?.title ?? domain
            let context = container.mainContext
            let bucket = Bucket(name: bucketName)
            context.insert(bucket)
            setSuggestion(bucket: bucket, explanation: "New bucket for links from \(domain)")
        }
    }

    private func computeImageSuggestion() {
        let buckets = fetchBuckets()
        if let bucket = buckets.first(where: { ($0.items ?? []).contains { $0.isImage } }) {
            setSuggestion(bucket: bucket, explanation: "This bucket already contains images")
        } else {
            let context = container.mainContext
            let bucket = Bucket(name: "Images")
            context.insert(bucket)
            setSuggestion(bucket: bucket, explanation: "New bucket for your saved images")
        }
    }

    private func setSuggestion(bucket: Bucket, explanation: String) {
        suggestedBucket = bucket
        suggestionState = .loaded(
            bucket: SuggestedBucket(
                name: bucket.name,
                customColorIndex: bucket.customColorIndex,
                customSymbolIndex: bucket.customSymbolIndex
            ),
            explanation: explanation
        )
    }

    private func findBestMatchingBucket(for url: URL, in buckets: [Bucket]) -> Bucket? {
        guard let domain = url.host else { return nil }
        var bestBucket: Bucket?
        var bestCount = 0

        for bucket in buckets {
            let matchingCount = (bucket.items ?? []).filter { $0.url?.host == domain }.count
            if matchingCount > bestCount {
                bestCount = matchingCount
                bestBucket = bucket
            }
        }

        return bestBucket
    }
}

#if DEBUG
#Preview {
    BucketPickerView(
        content: .url(URL(string: "https://apple.com")!)
    ) { }
    .modelContainer(PreviewSampleData.container)
}
#endif
