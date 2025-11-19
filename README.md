# KMReader

A native iOS client for [Komga](https://github.com/gotson/komga) - a media server for comics/mangas/BDs/magazines.

## Features

### 🔐 Authentication
- User login with Komga server
- Remember-me support and session management

### 📚 Browsing
- Browse libraries, series, and books
- **Series Filtering & Sorting**:
  - Filter by read status (All, Read, Unread, In Progress)
  - Filter by series status (All, Ongoing, Ended, Hiatus, Cancelled)
  - Sort by: Name, Date Added, Date Updated, Date Read, Release Date, Folder Name, Books Count, Random
  - Sort direction: Ascending/Descending (except Random)
  - Library filtering across all views
- **Series Details**:
  - Full metadata (title, status, age rating, language, publisher, authors, genres, tags, summary)
  - Reading direction and book count
  - Books list with reading progress indicators
  - Book list sorting (ascending/descending by book number)

### 📖 Reading Experience
- **Multiple Reading Modes**:
  - **LTR/RTL**: Horizontal page navigation (left-to-right or right-to-left)
  - **Vertical**: Vertical page scrolling
  - **Webtoon**: Continuous vertical scroll with adjustable page width (50%-100%)
  - Automatic reading direction detection from series metadata
  - Manual reading mode selection during reading
- **Reader Features**:
  - Pinch to zoom (1x to 4x), double-tap to zoom, drag to pan
  - Swipe/tap navigation between pages
  - Tap zones for page navigation
  - Auto-hide controls (3 seconds)
  - Reading direction picker, page counter, progress slider
  - End page view with next book navigation
  - Save current page to Photos or Files app (JPEG, PNG, HEIF, WebP formats supported)
  - Context menu on page images for quick save
- **Progress Tracking**:
  - Automatic progress sync to server
  - Resume from last read page
  - Mark as read/unread
  - Reading status indicators (UNREAD, IN_PROGRESS, READ)

### 📊 Dashboard
- **Keep Reading**: Books currently in progress (sorted by last read date)
- **On Deck**: Next books to read in series
- **Recently Added Books**: Latest additions to libraries
- **Recently Added Series**: New series added to libraries
- **Recently Updated Series**: Recently updated series
- Library filtering and pull to refresh

### 📜 History
- Recently read books with relative timestamps
- Reading progress display
- Library filtering
- Infinite scroll with automatic pagination
- Quick access to resume reading

### ⚙️ Settings
- **Appearance**:
  - Theme color selection (12 color options)
  - Browse columns adjustment (portrait/landscape, 1-8 columns)
  - Show/hide card titles
  - Preserve thumbnail aspect ratio
- **Reader**:
  - Webtoon page width adjustment (50% - 100%)
- **Cache**:
  - View disk cache size and cached image count
  - Adjust maximum disk cache size (512MB - 8GB, default 2GB)
  - Clear disk cache manually
  - Automatic cache cleanup when limit is exceeded
- **Account**:
  - User email and roles display
  - Logout

### 💾 Performance & Caching
- **Two-Tier Image Caching System**:
  - **Disk Cache**: Persistent storage (configurable, default 2GB, range 512MB-8GB)
  - **Memory Cache**: Fast access (up to 50 images, 200MB, LRU eviction)
- **Smart Image Loading**:
  - Load order: Memory cache → Disk cache → Network download
  - Automatic downscaling of large images to prevent OOM
  - Background image decoding
  - WebP format support
- **Page Preloading**: Intelligent preloading based on reading mode (1-3 pages ahead)
- **Thumbnail Caching**: Fast thumbnail loading for series and books

## Architecture

Built with SwiftUI following MVVM pattern:

- **Models**: Library, Series, Book, Page, Collection, ReadList
- **Services**: APIClient, AuthService, LibraryService, SeriesService, BookService, ImageCache
- **ViewModels**: AuthViewModel, LibraryViewModel, SeriesViewModel, BookViewModel, ReaderViewModel
- **Views**: Login, Dashboard, Browse, History, Settings, Reader (multiple modes), Series/Book details

## Setup

1. Open the project in Xcode 15+
2. Build and run on iOS 17+ device or simulator
3. On first launch, enter:
   - Your Komga server URL (e.g., `http://192.168.1.100:25600`)
   - Username
   - Password

## API Compatibility

Compatible with Komga API v1 and v2:

- ✅ User Authentication (API v2)
- ✅ Libraries, Series, Books (API v1)
- ✅ Reading Progress & Book Pages (API v1)
- ✅ Collections & Read Lists (API v1)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- A running Komga server

## Debugging

The app includes comprehensive API logging using Apple's unified logging system (OSLog).

**View logs in Xcode Console** or **Console.app**:
- Filter by process name: "Komga" or subsystem: "Komga"
- Category: "API"

**Log Format:**
```
📡 GET https://your-server.com/api/v2/users/me
✅ 200 GET https://your-server.com/api/v2/users/me (45.67ms)
```

**Log Symbols:**
- 📡 Request sent
- ✅ Successful response (200-299)
- ❌ Error response (400+) or network error
- 🔒 Unauthorized (401)
- ⚠️ Warning (e.g., empty response)

## TODO

### Reader Features
- [ ] Two page spread function when the screen is turned landscape
- [ ] Skip cover option for two page spread

### Collections & Read Lists
- [ ] Ability to view "Collections/Read Lists"
