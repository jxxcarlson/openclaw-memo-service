# Memo Viewer

A lightweight native macOS app that displays markdown files from your memo folders in a clean, searchable interface.

## Features

- **Two-tab interface** — Current memos and archived memos with year/month hierarchy
- **Auto-refresh** — Automatically detects new and deleted files every 2.5 seconds
- **Text search** — Quickly filter memos by filename
- **One Markdown integration** — Double-click to open files in One Markdown.app
- **Window persistence** — Remembers window size and position between sessions

## Requirements

- macOS 11+
- Xcode 15+
- Swift 5.9+
- [One Markdown.app](https://apps.apple.com/app/id1608371168) (optional but required for opening files)

## Folder Structure

The app looks for memos in:
- **Current memos:** `~/.openclaw/workspace/memos/` (flat structure)
- **Archived memos:** `~/.openclaw/workspace/memos-archive/` (organized by year/month)

## Building

1. Open `MemoViewerApp.xcodeproj` in Xcode
2. Set your Team ID in Signing & Capabilities
3. Build and run: `Cmd+R`

## Testing

Run tests with:
```bash
xcodebuild test -scheme MemoViewer
```

## Architecture

- **Models:** `MemoFile`, `MemoFolder`, `MemoTree`, `MonthNode`
- **Views:** `ContentView`, `CurrentMemosView`, `ArchiveView`, `SearchField`
- **Utilities:** `FileSystemHelper` for safe directory operations
- **App:** `MemoViewerApp` with window persistence

## Future Enhancements

- Event-based file monitoring (FSEvents) for more efficient updates
- Sorting options (by name, by date modified)
- File previews
- Tags and custom metadata
