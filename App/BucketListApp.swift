//
//  bucket_listApp.swift
//  bucket-list
//
//  Created by Ochmann, David on 17.02.26.
//

import SwiftData
import SwiftUI

@main
struct BucketListApp: App {
    @State private var syncMonitor = SyncMonitor()

    init() {
        MinimalDesign.configureNavigationBar()
    }

    var body: some Scene {
        WindowGroup {
            InboxListView()
                .overlay(alignment: .bottom) {
                    SyncStatusOverlay(isSyncing: syncMonitor.isSyncing)
                        .padding(.bottom, 8)
                }
                .animation(.easeInOut, value: syncMonitor.isSyncing)
        }
        .modelContainer(SharedModelContainer.container)
    }
}
