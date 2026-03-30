//
//  FullScreenImageView.swift
//  bucket-list
//

import SwiftUI
import UIKit

struct FullScreenImageView: View {
    let imageData: Data
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .white.opacity(0.3))
                }
                .padding()
            }
            .onTapGesture {
                dismiss()
            }
        }
    }
}

#if DEBUG
#Preview {
    FullScreenImageView(imageData: PreviewSampleData.sampleImageData)
}
#endif
