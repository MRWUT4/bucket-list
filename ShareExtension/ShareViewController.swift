//
//  ShareViewController.swift
//  ShareExtension
//

import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            close()
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
                self?.handleLoadedItem(data)
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                self?.handleLoadedItem(data)
            }
        } else {
            close()
        }
    }

    private func handleLoadedItem(_ data: (any Sendable)?) {
        var url: URL?
        if let directURL = data as? URL {
            url = directURL
        } else if let urlData = data as? Data {
            url = URL(dataRepresentation: urlData, relativeTo: nil)
        } else if let text = data as? String {
            url = URL(string: text)
        }

        DispatchQueue.main.async {
            guard let url else {
                self.close()
                return
            }
            self.showBucketPicker(for: url)
        }
    }

    private func showBucketPicker(for url: URL) {
        let picker = BucketPickerView(url: url) { [weak self] in
            self?.close()
        }

        let hostingController = UIHostingController(rootView: picker)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
