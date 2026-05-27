# Memo Viewer macOS App — Design Spec

**Date:** 2026-05-27  
**Status:** Approved  
**Technology:** Swift + SwiftUI  

## Overview

A lightweight native macOS app that displays markdown files from two folders (`memos/` and `memos-archive/`) as browsable, clickable lists. Files open in One Markdown.app via double-click. The app stays open in the Dock and auto-refreshes as new files appear.

## Requirements

### Functional

1. **Two-tab interface**
   - Tab 1: "Current Memos" — flat list of `.md` files from `memos/` folder
   - Tab 2: "Archive" — hierarchical tree (Year → Month → Files) from `memos-archive/` folder

2. **File listing**
   - Current Memos sorted by file creation date (newest first)
   - Archive organized by year and month (expandable outline)
   - Only `.md` files shown; hidden files (starting with `.`) ignored

3. **Search functionality**
   - Simple text search field at top of each tab
   - Filters displayed list by filename (case-insensitive, partial match)
   - Filters across all years/months in Archive tab

4. **File opening**
   - Double-click any file to open in One Markdown.app
   - If One Markdown.app not installed: show error alert (graceful failure)

5. **Auto-refresh**
   - Every 2-3 seconds: rescan both folders for new/deleted/modified files
   - Update UI automatically when changes detected
   - Maintain list position (don't jump to top on refresh)

6. **Window persistence**
   - Remember window size and position between app launches

### Non-Functional

- **Performance:** Should handle 1000+ files without lag
- **Reliability:** App should not crash if folders are missing or inaccessible
- **Responsiveness:** Search and UI updates should feel instant

## Architecture

### Layers

**UI Layer (SwiftUI)**
- `ContentView` — main tab view container
- `CurrentMemosView` — flat list with search
- `ArchiveView` — hierarchical outline with search
- `SearchField` — reusable search input component

**Model Layer**
- `MemoFolder` — manages file scanning, caching, and refresh logic
- `MemoFile` — lightweight struct representing a single markdown file (path, name, creation date)
- `MemoTree` — represents hierarchical structure (Year/Month/File) for archive

**File System Layer**
- FileManager wrapper for safe directory scanning
- Error handling for missing/inaccessible folders

### Data Flow

**Startup:**
1. Read `memos/` → build flat list of `.md` files, sort by creation date
2. Read `memos-archive/` → recursively build year/month tree structure
3. Populate both tab views

**Background (every 2-3 seconds):**
1. Re-scan both folders
2. Compare file lists with previous state
3. Update UI if changes detected
4. Search filters applied client-side (no file system calls during search)

**File Opening:**
1. User double-clicks file
2. Construct full file path
3. Use `NSWorkspace.shared.open(fileURL, withAppBundleIdentifier: "com.one-markdown.app")`
4. Show error alert if app not found

## Implementation Scope

### In Scope

- File listing (flat + hierarchical)
- Auto-refresh on a timer
- Text search (filename only)
- Double-click to open
- Window position/size persistence
- Error handling (missing folders, missing app)

### Out of Scope (Future)

- File preview/thumbnails
- Drag-and-drop between folders
- Creating new memos from the app
- Text search inside memo files
- Recursive search across file content
- Tags or custom metadata

## Error Handling

| Scenario | Behavior |
|----------|----------|
| `memos/` or `memos-archive/` doesn't exist | Show empty list, don't crash |
| One Markdown.app not installed | Alert on double-click: "One Markdown not found" |
| File deleted while app running | Removed from list on next refresh |
| Folder permission denied | Show empty list (skip inaccessible folder) |
| Extremely large folder (1000+ files) | Load all files, may take a moment on first scan |

## File Structure (Proposed)

```
MemoViewerApp/
├── MemoViewer/
│   ├── MemoViewerApp.swift          # Entry point
│   ├── Views/
│   │   ├── ContentView.swift        # Tab container
│   │   ├── CurrentMemosView.swift   # Flat list
│   │   ├── ArchiveView.swift        # Hierarchical tree
│   │   └── SearchField.swift        # Reusable search component
│   ├── Models/
│   │   ├── MemoFolder.swift         # File scanning + refresh logic
│   │   ├── MemoFile.swift           # Single file representation
│   │   └── MemoTree.swift           # Hierarchical structure for archive
│   └── Utilities/
│       └── FileSystemHelper.swift   # FileManager wrapper
├── MemoViewerTests/
│   ├── MemoFolderTests.swift
│   └── FileSystemHelperTests.swift
└── README.md
```

## Success Criteria

✅ User can launch app and see both Current Memos and Archive tabs  
✅ Clicking search field filters list instantly  
✅ Double-clicking a file opens it in One Markdown.app  
✅ New files appear in the list within 2-3 seconds of being created  
✅ App stays open and usable across multiple file operations  
✅ App handles missing/invalid folders gracefully  
✅ Window size/position remembered on next launch  

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| Polling (not FSEvents) for refresh | Simpler to implement, negligible CPU overhead for small file sets |
| Client-side search filtering | No file system calls during search, instant response |
| NSWorkspace for file opening | Standard, reliable way to launch files with specific app |
| SwiftUI (not AppKit) | Modern, cleaner code, easier to maintain |

## Future Enhancements

- Use `DispatchSourceFileSystemObject` for event-based monitoring (more efficient)
- Add sorting options (by name, by date modified, etc.)
- Tags or folders within Current Memos
- Sync with cloud storage
- Dark mode support
