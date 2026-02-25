//
//  SyncMonitor.swift
//  bucket-list
//

import CoreData

@Observable
final class SyncMonitor {
    var isSyncing = false

    private var activeSyncEvents: Set<UUID> = []

    init() {
        Task {
            for await notification in NotificationCenter.default.notifications(
                named: NSPersistentCloudKitContainer.eventChangedNotification
            ) {
                guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { continue }

                if event.endDate == nil {
                    activeSyncEvents.insert(event.identifier)
                } else {
                    activeSyncEvents.remove(event.identifier)
                }
                isSyncing = !activeSyncEvents.isEmpty
            }
        }
    }
}
