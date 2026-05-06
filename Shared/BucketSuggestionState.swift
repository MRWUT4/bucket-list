//
//  BucketSuggestionState.swift
//  bucket-list
//

enum BucketSuggestionState {
    case loading
    case loaded(bucket: Bucket, explanation: String)
    case failed
}
