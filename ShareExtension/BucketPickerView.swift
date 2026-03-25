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

    @State private var buckets: [Bucket] = []
    @State private var showingNewBucket = false
    @State private var newBucketName = ""
    @State private var isAutoSorting = false
    @State private var autoSortMessage = ""
    @State private var showAutoSortResult = false
    private let container = SharedModelContainer.extensionContainer

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List(buckets) { bucket in
                    Button {
                        saveItem(to: bucket)
                        onDismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(bucket.name)
                                .font(.headline)
                            Text("\((bucket.items ?? []).count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                FloatingActionButton(systemImage: "sparkles") {
                    autoSortItem()
                }
                .disabled(isAutoSorting)
                .padding()
            }
            .navigationTitle("Save to Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewBucket = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.accent)
                    }
                }
            }
            .alert("New Bucket", isPresented: $showingNewBucket) {
                TextField("Name", text: $newBucketName)
                Button("Cancel", role: .cancel) { newBucketName = "" }
                Button("Add") {
                    createBucketAndSaveItem()
                }
                .disabled(newBucketName.isEmpty)
            }
            .alert("Auto-Sorted", isPresented: $showAutoSortResult) {
                Button("OK") { onDismiss() }
            } message: {
                Text(autoSortMessage)
            }
            .overlay {
                if isAutoSorting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView("Analyzing…")
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .onAppear { loadBuckets() }
    }

    // MARK: - Data Operations

    @MainActor
    private func loadBuckets() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Bucket>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        buckets = (try? context.fetch(descriptor)) ?? []
    }

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

    @MainActor
    private func createBucketAndSaveItem() {
        let context = container.mainContext
        let bucket = Bucket(name: newBucketName)
        context.insert(bucket)
        newBucketName = ""
        saveItem(to: bucket)
        onDismiss()
    }

    // MARK: - Auto-Sort

    private func autoSortItem() {
        switch content {
        case .url(let url):
            autoSortURL(url)
        case .image:
            autoSortImage()
        }
    }

    private func autoSortURL(_ url: URL) {
        isAutoSorting = true
        Task {
            let provider = LPMetadataProvider()
            let metadata = try? await provider.startFetchingMetadata(for: url)

            if SystemLanguageModel.default.isAvailable {
                do {
                    try await smartSort(url: url, metadata: metadata)
                } catch {
                    domainMatchFallback(url: url, metadata: metadata)
                }
            } else {
                domainMatchFallback(url: url, metadata: metadata)
            }

            isAutoSorting = false
            showAutoSortResult = true
        }
    }

    private func smartSort(url: URL, metadata: LPLinkMetadata?) async throws {
        let instructions = """
            You are a smart organizer that categorizes web links into topic buckets. \
            Prefer existing buckets when the content is related. \
            Only suggest a new bucket if no existing one fits well.
            """
        let session = LanguageModelSession(instructions: instructions)
        let prompt = buildSortPrompt(url: url, metadata: metadata)
        let response = try await session.respond(to: prompt, generating: BucketSuggestion.self)
        let suggestion = response.content

        if suggestion.isExistingBucket,
           let bucket = buckets.first(where: { $0.name == suggestion.bucketName }) {
            saveItem(to: bucket)
        } else {
            let context = container.mainContext
            let bucket = Bucket(name: suggestion.bucketName)
            context.insert(bucket)
            saveItem(to: bucket)
        }
        autoSortMessage = suggestion.explanation
    }

    private func buildSortPrompt(url: URL, metadata: LPLinkMetadata?) -> String {
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

    private func domainMatchFallback(url: URL, metadata: LPLinkMetadata?) {
        let domain = url.host ?? url.absoluteString
        let siteTitle = metadata?.title

        if let matchingBucket = findBestMatchingBucket(for: url) {
            saveItem(to: matchingBucket)
            autoSortMessage = "Saved to \"\(matchingBucket.name)\" — this link matches other items from \(domain)."
        } else {
            let bucketName = siteTitle ?? domain
            let context = container.mainContext
            let bucket = Bucket(name: bucketName)
            context.insert(bucket)
            saveItem(to: bucket)
            autoSortMessage = "Created new bucket \"\(bucketName)\" for links from \(domain)."
        }
    }

    private func autoSortImage() {
        if let bucket = buckets.first(where: { ($0.items ?? []).contains { $0.isImage } }) {
            saveItem(to: bucket)
            autoSortMessage = "Saved image to \"\(bucket.name)\" — this bucket already contains images."
        } else {
            let context = container.mainContext
            let bucket = Bucket(name: "Images")
            context.insert(bucket)
            saveItem(to: bucket)
            autoSortMessage = "Created new bucket \"Images\" for your saved images."
        }
        showAutoSortResult = true
    }

    private func findBestMatchingBucket(for url: URL) -> Bucket? {
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
