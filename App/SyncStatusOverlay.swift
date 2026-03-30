//
//  SyncStatusOverlay.swift
//  bucket-list
//

import SwiftUI

struct SyncStatusOverlay: View {
    var isSyncing: Bool

    var body: some View {
        if isSyncing {
            HStack(spacing: 8) {
                ProgressView()
                Text("Syncing…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview("Syncing") {
    SyncStatusOverlay(isSyncing: true)
}

#Preview("Idle") {
    SyncStatusOverlay(isSyncing: false)
}
