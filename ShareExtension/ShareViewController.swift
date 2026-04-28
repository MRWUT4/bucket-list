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
        MinimalDesign.configureNavigationBar()

        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            close()
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
                self?.handleURLItem(data)
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, _ in
                self?.handleImageItem(data)
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                self?.handleURLItem(data)
            }
        } else {
            close()
        }
    }

    private func handleURLItem(_ data: (any Sendable)?) {
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
            self.showBucketPicker(sharedContent: .url(url))
        }
    }

    private func handleImageItem(_ data: (any Sendable)?) {
        var imageData: Data?

        if let url = data as? URL {
            imageData = try? Data(contentsOf: url)
        } else if let data = data as? Data {
            imageData = data
        } else if let image = data as? UIImage {
            imageData = image.jpegData(compressionQuality: 0.8)
        }

        DispatchQueue.main.async {
            guard let imageData else {
                self.close()
                return
            }
            self.showBucketPicker(sharedContent: .image(imageData))
        }
    }

    private func showBucketPicker(sharedContent: SharedContent) {
        let picker = BucketPickerView(content: sharedContent) { [weak self] in
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
