//
//  BucketSuggestionState.swift
//  bucket-list
//

struct SuggestedBucket {
    let name: String
    let customColorIndex: Int
    let customSymbolIndex: Int
}

enum BucketSuggestionState {
    case loading
    case loaded(bucket: SuggestedBucket, explanation: String)
    case failed
}
