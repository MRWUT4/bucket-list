//
//  LinkPreviewView.swift
//  bucket-list
//

import LinkPresentation
import SwiftUI

#if os(macOS)
import AppKit

struct LinkPreviewView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
        fetchMetadata(for: linkView)
        return linkView
    }

    func updateNSView(_ nsView: LPLinkView, context: Context) {}

    private func fetchMetadata(for linkView: LPLinkView) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, _ in
            if let metadata {
                DispatchQueue.main.async {
                    linkView.metadata = metadata
                }
            }
        }
    }
}
#else
import UIKit

struct LinkPreviewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
        fetchMetadata(for: linkView)
        return linkView
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {}

    private func fetchMetadata(for linkView: LPLinkView) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, _ in
            if let metadata {
                DispatchQueue.main.async {
                    linkView.metadata = metadata
                }
            }
        }
    }
}
#endif

#Preview {
    LinkPreviewView(url: URL(string: "https://apple.com")!)
        .frame(height: 200)
        .padding()
}
