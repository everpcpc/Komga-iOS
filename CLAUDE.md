# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KMReader is a native iOS, macOS, and tvOS client for Komga (https://github.com/gotson/komga), a media server for comics, manga, BDs, and magazines. The app supports both DIVINA (comic) and EPUB readers with comprehensive features for browsing, reading, and managing digital comics.

**Platforms:**
- iOS 17.6+
- macOS 14.0+
- tvOS 17.6+

**Key Dependencies:**
- Readium Swift Toolkit (3.5.0+) - EPUB reading functionality
- SDWebImage & SDWebImageSwiftUI - Image loading and caching with WebP support
- SwiftData - Persistent storage for server instances, libraries, and custom fonts
- SwiftSoup - HTML parsing for EPUB content

## Build Commands

```bash
# Build the project
xcodebuild -project KMReader.xcodeproj -scheme KMReader build

# Build for specific platform
xcodebuild -project KMReader.xcodeproj -scheme KMReader -sdk iphoneos build
xcodebuild -project KMReader.xcodeproj -scheme KMReader -sdk macosx build
xcodebuild -project KMReader.xcodeproj -scheme KMReader -sdk appletvos build

# Open in Xcode
open KMReader.xcodeproj

# Clean build folder
xcodebuild -project KMReader.xcodeproj -scheme KMReader clean
```

**Test Simulator:** iPhone 11 Pro Max (as specified in .cursor rules)

## Code Architecture

### SwiftUI & Observable Pattern

This is a **modern SwiftUI app** using the `@Observable` macro (Swift 5.9+) and `@MainActor` isolation:

- **ViewModels** use `@Observable` and `@MainActor` - NOT `ObservableObject`
- Views inject environment objects via `.environment()` - NOT `.environmentObject()`
- State management uses `@State`, `@AppStorage`, and SwiftData's `@Query`
- Concurrency uses structured async/await throughout

### Core Service Layer

**APIClient (Singleton)**
- `APIClient.shared` - Centralized HTTP client with automatic auth token injection
- Supports JSON decoding with detailed error logging
- Custom `APIError` types with URL context for debugging
- Configured URLSession with 50MB memory cache, 500MB disk cache

**Authentication & Multi-Server**
- `AuthViewModel` - Manages login/logout state, current user
- `KomgaInstanceStore` - SwiftData-backed store for multiple server profiles
- `AuthService` - Handles login, user info, authentication activity logs
- Each server instance stores: URL, username, authToken, isAdmin flag, displayName
- Active credentials stored in `AppConfig.serverURL` and `AppConfig.authToken`

**Cache System (Three-Tier)**

The app uses **three separate caches** managed through namespaced directories:

1. **Page Cache (`ImageCache`)** - `KomgaImageCache` namespace
   - Stores raw comic page images (DIVINA format)
   - Configurable limit: 512MB-8GB (default 2GB, configurable via `AppConfig.maxDiskCacheSizeMB`)
   - Auto-cleanup when exceeding 90% of limit
   - Uses `CacheSizeActor` for thread-safe size tracking
   - Scoped per-server using `CacheNamespace.directory(for:)`

2. **Book File Cache (`BookFileCache`)** - `KomgaBookFileCache` namespace
   - Stores complete EPUB files for offline reading
   - Default 5GB limit
   - Async download/storage for EPUB books
   - Server-scoped like page cache

3. **Thumbnail Cache (`SDImageCacheProvider`)**
   - Two SDWebImage caches: `thumbnailCache` and `pageImageCache`
   - WebP codec support configured at app startup
   - Auth token injected via custom request modifier
   - Separate from page/book caches

**Cache Namespace System:**
- `CacheNamespace.directory(for: String)` - Returns server-scoped cache directory
- Cache paths include `instanceId` to isolate data between servers
- Deleting a server instance clears all associated caches automatically

### Data Services

All services follow the singleton pattern (`ServiceName.shared`):

- **`BookService`** - Book metadata, pages, read progress, search
- **`SeriesService`** - Series listing, metadata, filtering, sorting
- **`CollectionService`** - Collections CRUD, series management
- **`ReadListService`** - Read lists CRUD, book management
- **`LibraryService`** - Library operations, scanning, metadata refresh
- **`LibraryManager`** - Loads and manages available libraries, exposes `@Published var libraries`

### ViewModels

ViewModels use `@Observable` and handle:
- Async data loading from services
- Pagination state (currentPage, hasMorePages)
- Error handling via `ErrorManager.shared.alert(error:)`
- Loading states with `isLoading` flag

Key ViewModels:
- **`BookViewModel`** - Books browsing, filtering, read progress updates
- **`SeriesViewModel`** - Series browsing with complex filtering/sorting
- **`CollectionViewModel`** - Collections management
- **`ReadListViewModel`** - Read lists management
- **`AuthViewModel`** - Authentication state, injected into environment

### View Layer Organization

```
Views/
├── Auth/              # Login, landing, server management
├── Dashboard/         # Home screen with "Keep Reading", "On Deck", etc.
├── Browse/            # Unified browse view (Series/Books/Collections/ReadLists)
├── Series/            # Series detail, context menus, filters
├── Book/              # Book detail, context menus, sections
├── Collection/        # Collection views and management
├── ReadList/          # Read list views and management
├── Reader/            # Comic (DIVINA) and EPUB readers
│   ├── DivinaReaderView.swift    # Comic reader (LTR/RTL/Vertical/Webtoon)
│   ├── EpubReaderView.swift      # EPUB reader (iOS/macOS only)
│   ├── ReaderControlsView.swift  # Reader toolbar
│   └── PageView/      # Page rendering components
├── History/           # Reading history
├── Settings/          # App settings, cache management
└── Components/        # Reusable components (ThumbnailImage, InfoRow, etc.)
```

### Reader Implementation

**DIVINA Reader (`DivinaReaderView`)**
- Supports 4 reading modes: LTR, RTL, Vertical, Webtoon
- Page layouts: Single page, Dual page (landscape)
- Platform support: iOS, macOS, tvOS
- Features: Zoom (iOS/macOS), tap zones, auto-hide controls, incognito mode
- Page preloading with `ImageCache`
- macOS: Dedicated reader window (`ReaderWindowView`)

**EPUB Reader (`EpubReaderView`)**
- Platform support: iOS, macOS only (NOT tvOS)
- Uses Readium Swift Toolkit for rendering
- Features: Custom fonts, adjustable size, themes, ToC, offline support
- Optional "image view" mode for comic-like rendering
- Full-book downloads via `BookFileCache`

**Reading Direction (`ReadingDirection` enum)**
- `.ltr` - Left-to-right (Western comics)
- `.rtl` - Right-to-left (Manga)
- `.vertical` - Vertical scrolling
- `.webtoon` - Webtoon mode (iOS only)
- Platform-aware: `availableCases` excludes webtoon on macOS/tvOS

### Navigation & State

- Tab-based navigation: Dashboard, Browse, History, Settings
- `@AppStorage` for persistent preferences (theme color, layout modes, cache limits)
- `NavDestination` enum drives NavigationPath for deep linking
- Browse views support both Grid and List layouts with orientation-aware column counts

### Error Handling

**`ErrorManager` (Singleton)**
- `alert(error:)` - Shows error alert dialog
- `notify(message:)` - Shows temporary notification toast
- Centralized error presentation across the app
- Supports copying error messages to clipboard (iOS/macOS)

**`APIError` enum** - Wraps HTTP errors with context:
- `.unauthorized`, `.forbidden`, `.notFound`
- `.badRequest`, `.serverError`, `.httpError`
- `.networkError` - Wraps `AppErrorType` for network failures
- All cases include `url: String` for debugging

### Models & Data Types

**Key Models:**
- `Book`, `Series`, `Collection`, `ReadList` - Decodable API models
- `Library` - Represents Komga library
- `User`, `KomgaInstance` (SwiftData) - Auth and server instances
- `ReadProgress` - Tracks reading position
- `BookPage`, `Page` - Page metadata for readers

**Browse System:**
- `BrowseContentType` - Series, Books, Collections, ReadLists
- `BrowseLayoutMode` - Grid, List
- `BrowseLayoutHelper` - Manages layout state and column counts
- Separate portrait/landscape column preferences

**Filtering & Sorting:**
- Each content type has dedicated filter/sort options
- `SeriesSortField`, `BookSortField` with protocol `SortFieldProtocol`
- `ReadStatusFilter` - Unread, InProgress, Read
- `SeriesStatusFilter` - Ongoing, Ended, Abandoned, Hiatus

## Coding Standards (from .cursor/rules/default.mdc)

1. **Use UIKit as little as possible** - Prefer pure SwiftUI solutions
2. **Do not use inline Binding** - Extract bindings to separate variables for clarity
3. **Do not use confirmationDialog** - Use alternative SwiftUI dialogs
4. **Comment in English** - All comments must be in English

## Platform Considerations

**iOS-specific:**
- Full feature set including Webtoon mode and EPUB reader
- Supports all reading modes and gestures (pinch-to-zoom)
- Save pages to Photos or Files

**macOS-specific:**
- Dedicated reader window (`WindowGroup(id: "reader")`)
- EPUB reader support
- Reader background and controls adapted for desktop

**tvOS-specific:**
- DIVINA reader only (NO EPUB, NO Webtoon)
- Focus-based navigation with remote control
- Limited to LTR, RTL, Vertical reading modes

## Common Development Patterns

**Loading Data with Pagination:**
```swift
func loadItems(refresh: Bool = false) async {
    if refresh {
        currentPage = 0
        hasMorePages = true
        items = []
    }
    guard hasMorePages && !isLoading else { return }
    isLoading = true
    do {
        let page = try await service.getItems(page: currentPage, size: 20)
        withAnimation {
            items.append(contentsOf: page.content)
        }
        hasMorePages = !page.last
        currentPage += 1
    } catch {
        ErrorManager.shared.alert(error: error)
    }
    isLoading = false
}
```

**Using APIClient:**
```swift
let result: MyModel = try await APIClient.shared.request(
    path: "/api/v1/resource",
    method: "GET",
    queryItems: [URLQueryItem(name: "page", value: "0")]
)
```

**Cache Operations:**
```swift
// Clear cache for specific book
await CacheManager.clearCache(forBookId: bookId)

// Clear cache for server instance
await CacheManager.clearCaches(instanceId: instanceId)

// Get cache size/count
let size = await ImageCache.getDiskCacheSize()
let count = await ImageCache.getDiskCacheCount()
```

**SwiftData Queries:**
```swift
@Query(sort: \KomgaInstance.lastUsedAt, order: .reverse)
private var instances: [KomgaInstance]
```

## Debugging & Logging

**Logs use OSLog:**
- Subsystem: "KMReader" or `Bundle.main.bundleIdentifier ?? "KMReader"`
- Category: "API", "ImageCache", etc.
- Filter in Console.app by subsystem "KMReader" or process "Komga"

**API Logging Format:**
```
📡 GET https://server.com/api/v1/books
✅ 200 GET https://server.com/api/v1/books (45.67ms)
❌ 404 GET https://server.com/api/v1/books/invalid-id
```

## Important Implementation Notes

1. **Avoid UIKit** unless absolutely necessary for platform features
2. **Use `@Observable` not `ObservableObject`** for ViewModels
3. **Always scope caches to server instance** via `CacheNamespace`
4. **Handle platform differences** with `#if os(iOS)` / `#if os(macOS)` / `#if os(tvOS)`
5. **EPUB features are iOS/macOS only** - tvOS supports DIVINA only
6. **Webtoon mode is iOS only** - exclude from macOS/tvOS
7. **All async operations use structured concurrency** - no completion handlers
8. **Errors go through ErrorManager** for consistent presentation
9. **Reading progress auto-syncs** unless in incognito mode
10. **Cache cleanup is automatic** when exceeding limits
