# Copilot Instructions

## Project Overview

This is **bucket-list**, a SwiftUI app for saving URLs for later consumption. It uses the `LinkPresentation` framework (`LPMetadataProvider`, `LPLinkMetadata`) to fetch and display rich URL previews. The app targets iOS, macOS, and visionOS and uses an Xcode project (not Swift Package Manager) with a single `bucket-list` target.

## Build Commands

```bash
# Build for macOS
xcodebuild -project bucket-list.xcodeproj -scheme bucket-list -destination 'platform=macOS' build

# Build for iOS Simulator
xcodebuild -project bucket-list.xcodeproj -scheme bucket-list -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

- **App entry point**: `bucket_listApp.swift` — standard SwiftUI `@main` App struct using `WindowGroup`.
- **UI layer**: SwiftUI views in `bucket-list/`. The navigation flow is:
  1. **Bucket list** (`InboxListView`): Root view showing all buckets. A FAB lets users create new buckets.
  2. **Bucket detail** (`BucketListView`): Tapping a bucket navigates to its saved URLs, each rendered as a rich preview via `LinkPresentation`. A FAB opens a sheet to add a new URL.
  3. **Share Extension**: iOS share sheet extension that shows the bucket list and saves the shared URL to the selected bucket.
- **Shared data**: `SharedModelContainer` provides a SwiftData `ModelContainer` backed by an App Group (`group.de.davidochmann.bucketlist`) and synced via CloudKit (`iCloud.de.davidochmann.bucketlist`) so the main app and share extension access the same database, and data syncs across devices on the same iCloud account.
- **CloudKit requirements**: All `@Model` properties must have default values (no required initializer-only properties). Do not use `@Attribute(.unique)` — CloudKit does not support unique constraints.
- No test target is currently configured.

## Key Conventions

- **Swift concurrency**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES` are enabled — all types default to `@MainActor` isolation. Only opt out explicitly with `nonisolated` when needed.
- **Member import visibility**: `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` is enabled — explicitly import modules whose members you use.
- **Deployment targets**: 26.2 across iOS, macOS, and visionOS.
- **Swift version**: 5.0 with modern concurrency features enabled.
- Source files are managed via Xcode's file system synchronization (`PBXFileSystemSynchronizedRootGroup`), so new files added to the `bucket-list/` directory are automatically included in the build.
