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
    var body: some Scene {
        WindowGroup {
            InboxListView()
        }
        .modelContainer(SharedModelContainer.container)
    }
}
