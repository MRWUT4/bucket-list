//
//  AddURLSheet.swift
//  bucket-list
//

import SwiftUI

struct AddURLSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlText = ""

    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("https://example.com", text: $urlText)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
                    .autocorrectionDisabled()
            }
            .navigationTitle("Add URL")
//            #if os(iOS)
//            .navigationBarTitleDisplayMode(.inline)
//            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(urlText)
                        dismiss()
                    }
                    .disabled(URL(string: urlText) == nil || urlText.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddURLSheet { _ in }
}
