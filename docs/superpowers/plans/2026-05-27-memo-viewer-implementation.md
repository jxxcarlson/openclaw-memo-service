# Memo Viewer macOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS app that displays markdown files from `memos/` and `memos-archive/` folders in a two-tab interface with auto-refresh, text search, and file opening in One Markdown.app.

**Architecture:** Model-View separation with a `MemoFolder` class managing file scanning and refresh logic, SwiftUI views for UI, and a FileSystemHelper utility for safe directory operations. Auto-refresh every 2.5 seconds via a Timer, client-side search filtering, and NSWorkspace for file opening.

**Tech Stack:** Swift 5.9+, SwiftUI, Xcode 15+, Foundation (FileManager, NSWorkspace)

---

## File Structure

```
MemoViewerApp/
├── MemoViewer/
│   ├── MemoViewerApp.swift              # App entry point
│   ├── Models/
│   │   ├── MemoFile.swift               # Single file representation
│   │   ├── MemoTree.swift               # Year/Month/File hierarchy
│   │   └── MemoFolder.swift             # File scanning & refresh
│   ├── Views/
│   │   ├── ContentView.swift            # Tab container
│   │   ├── CurrentMemosView.swift       # Flat list view
│   │   ├── ArchiveView.swift            # Hierarchical tree view
│   │   └── SearchField.swift            # Reusable search input
│   └── Utilities/
│       └── FileSystemHelper.swift       # FileManager wrapper
├── MemoViewerTests/
│   ├── MemoFileTests.swift
│   ├── FileSystemHelperTests.swift
│   └── MemoFolderTests.swift
└── README.md
```

---

## Task 1: Project Setup

**Files:**
- Create Xcode project: `MemoViewerApp`

- [ ] **Step 1: Create Xcode project**

Open Xcode and create a new macOS app project:
- Product name: `MemoViewer`
- Team: (your team)
- Organization Identifier: `com.carlson`
- Bundle Identifier: `com.carlson.memo-viewer`
- Interface: SwiftUI
- Language: Swift
- Storage: None

Create the folder structure:
```bash
mkdir -p MemoViewer/Models
mkdir -p MemoViewer/Views
mkdir -p MemoViewer/Utilities
mkdir -p MemoViewerTests
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "project: create MemoViewer Xcode project structure"
```

---

## Task 2: MemoFile Model

**Files:**
- Create: `MemoViewer/Models/MemoFile.swift`
- Test: `MemoViewerTests/MemoFileTests.swift`

- [ ] **Step 1: Write the test**

```swift
// MemoViewerTests/MemoFileTests.swift
import XCTest
@testable import MemoViewer

class MemoFileTests: XCTestCase {
    
    func testMemoFileInitialization() {
        let url = URL(fileURLWithPath: "/Users/test/memos/test.md")
        let creationDate = Date(timeIntervalSince1970: 0)
        
        let memo = MemoFile(url: url, name: "test.md", creationDate: creationDate)
        
        XCTAssertEqual(memo.name, "test.md")
        XCTAssertEqual(memo.url, url)
        XCTAssertEqual(memo.creationDate, creationDate)
    }
    
    func testMemoFileComparison() {
        let url1 = URL(fileURLWithPath: "/Users/test/memos/a.md")
        let url2 = URL(fileURLWithPath: "/Users/test/memos/b.md")
        let date1 = Date(timeIntervalSince1970: 100)
        let date2 = Date(timeIntervalSince1970: 200)
        
        let memo1 = MemoFile(url: url1, name: "a.md", creationDate: date1)
        let memo2 = MemoFile(url: url2, name: "b.md", creationDate: date2)
        
        // memo2 is newer, should come first when sorted descending
        let sorted = [memo1, memo2].sorted { $0.creationDate > $1.creationDate }
        XCTAssertEqual(sorted[0].name, "b.md")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme MemoViewer -only-testing MemoViewerTests/MemoFileTests
```

Expected: `Build failed` (struct not yet defined)

- [ ] **Step 3: Implement MemoFile**

```swift
// MemoViewer/Models/MemoFile.swift
import Foundation

struct MemoFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let creationDate: Date
    
    var displayName: String {
        // Remove .md extension for display
        name.replacingOccurrences(of: ".md", with: "")
    }
    
    static func == (lhs: MemoFile, rhs: MemoFile) -> Bool {
        lhs.url == rhs.url
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme MemoViewer -only-testing MemoViewerTests/MemoFileTests
```

Expected: `Test Suite 'MemoFileTests' passed`

- [ ] **Step 5: Commit**

```bash
git add MemoViewer/Models/MemoFile.swift MemoViewerTests/MemoFileTests.swift
git commit -m "feat: add MemoFile model"
```

---

## Task 3: FileSystemHelper Utility

**Files:**
- Create: `MemoViewer/Utilities/FileSystemHelper.swift`
- Test: `MemoViewerTests/FileSystemHelperTests.swift`

- [ ] **Step 1: Write the test**

```swift
// MemoViewerTests/FileSystemHelperTests.swift
import XCTest
@testable import MemoViewer

class FileSystemHelperTests: XCTestCase {
    
    var testDir: URL!
    var memosDir: URL!
    
    override func setUp() {
        super.setUp()
        testDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        memosDir = testDir.appendingPathComponent("memos")
        try? FileManager.default.createDirectory(at: memosDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: testDir)
        super.tearDown()
    }
    
    func testScanMarkdownFiles() {
        // Create test markdown files
        let file1 = memosDir.appendingPathComponent("test1.md")
        let file2 = memosDir.appendingPathComponent("test2.md")
        FileManager.default.createFile(atPath: file1.path, contents: nil)
        FileManager.default.createFile(atPath: file2.path, contents: nil)
        
        let files = FileSystemHelper.scanMarkdownFiles(in: memosDir)
        
        XCTAssertEqual(files.count, 2)
        XCTAssertTrue(files.contains { $0.name == "test1.md" })
        XCTAssertTrue(files.contains { $0.name == "test2.md" })
    }
    
    func testScanIgnoresHiddenFiles() {
        let visibleFile = memosDir.appendingPathComponent("visible.md")
        let hiddenFile = memosDir.appendingPathComponent(".hidden.md")
        FileManager.default.createFile(atPath: visibleFile.path, contents: nil)
        FileManager.default.createFile(atPath: hiddenFile.path, contents: nil)
        
        let files = FileSystemHelper.scanMarkdownFiles(in: memosDir)
        
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files[0].name, "visible.md")
    }
    
    func testScanNonexistentFolderReturnsEmpty() {
        let nonexistent = testDir.appendingPathComponent("nonexistent")
        let files = FileSystemHelper.scanMarkdownFiles(in: nonexistent)
        
        XCTAssertEqual(files.count, 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme MemoViewer -only-testing MemoViewerTests/FileSystemHelperTests
```

Expected: `Build failed` (FileSystemHelper not yet defined)

- [ ] **Step 3: Implement FileSystemHelper**

```swift
// MemoViewer/Utilities/FileSystemHelper.swift
import Foundation

class FileSystemHelper {
    static func scanMarkdownFiles(in folder: URL) -> [MemoFile] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey]
            )
            
            let markdownFiles = contents.filter { url in
                let isHidden = url.lastPathComponent.hasPrefix(".")
                let isMarkdown = url.pathExtension.lowercased() == "md"
                return !isHidden && isMarkdown
            }
            
            return markdownFiles.compactMap { url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.creationDateKey])
                    let creationDate = resourceValues.creationDate ?? Date()
                    
                    return MemoFile(
                        url: url,
                        name: url.lastPathComponent,
                        creationDate: creationDate
                    )
                } catch {
                    return nil
                }
            }
        } catch {
            // Folder doesn't exist or is inaccessible
            return []
        }
    }
    
    static func scanHierarchical(in folder: URL) -> [(year: String, months: [(month: String, files: [MemoFile])])] {
        do {
            let yearFolders = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil
            ).filter { url in
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                return isDir.boolValue && !url.lastPathComponent.hasPrefix(".")
            }
            
            return yearFolders.sorted { $0.lastPathComponent > $1.lastPathComponent }.compactMap { yearURL in
                let year = yearURL.lastPathComponent
                
                do {
                    let monthFolders = try FileManager.default.contentsOfDirectory(
                        at: yearURL,
                        includingPropertiesForKeys: nil
                    ).filter { url in
                        var isDir: ObjCBool = false
                        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                        return isDir.boolValue && !url.lastPathComponent.hasPrefix(".")
                    }
                    
                    let months = monthFolders.sorted { $0.lastPathComponent > $1.lastPathComponent }.compactMap { monthURL in
                        let month = monthURL.lastPathComponent
                        let files = scanMarkdownFiles(in: monthURL).sorted { $0.creationDate > $1.creationDate }
                        return (month: month, files: files)
                    }
                    
                    return (year: year, months: months)
                } catch {
                    return nil
                }
            }
        } catch {
            return []
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme MemoViewer -only-testing MemoViewerTests/FileSystemHelperTests
```

Expected: `Test Suite 'FileSystemHelperTests' passed`

- [ ] **Step 5: Commit**

```bash
git add MemoViewer/Utilities/FileSystemHelper.swift MemoViewerTests/FileSystemHelperTests.swift
git commit -m "feat: add FileSystemHelper for directory scanning"
```

---

## Task 4: MemoTree Model

**Files:**
- Create: `MemoViewer/Models/MemoTree.swift`

- [ ] **Step 1: Implement MemoTree**

```swift
// MemoViewer/Models/MemoTree.swift
import Foundation

class MemoTree: Identifiable, ObservableObject {
    let id = UUID()
    let year: String
    @Published var months: [MonthNode] = []
    
    init(year: String, months: [MonthNode] = []) {
        self.year = year
        self.months = months
    }
}

class MonthNode: Identifiable, ObservableObject {
    let id = UUID()
    let month: String
    @Published var files: [MemoFile] = []
    @Published var isExpanded: Bool = false
    
    init(month: String, files: [MemoFile] = []) {
        self.month = month
        self.files = files
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MemoViewer/Models/MemoTree.swift
git commit -m "feat: add MemoTree hierarchical structure"
```

---

## Task 5: MemoFolder Model (File Scanning & Refresh)

**Files:**
- Create: `MemoViewer/Models/MemoFolder.swift`
- Test: `MemoViewerTests/MemoFolderTests.swift`

- [ ] **Step 1: Write the test**

```swift
// MemoViewerTests/MemoFolderTests.swift
import XCTest
@testable import MemoViewer

class MemoFolderTests: XCTestCase {
    
    var testDir: URL!
    var memosDir: URL!
    var archiveDir: URL!
    
    override func setUp() {
        super.setUp()
        testDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        memosDir = testDir.appendingPathComponent("memos")
        archiveDir = testDir.appendingPathComponent("memos-archive")
        try? FileManager.default.createDirectory(at: memosDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: testDir)
        super.tearDown()
    }
    
    func testMemoFolderInitialization() {
        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)
        
        XCTAssertEqual(folder.currentMemos.count, 0)
        XCTAssertEqual(folder.archiveTree.count, 0)
    }
    
    func testLoadCurrentMemos() {
        // Create test files
        let file1 = memosDir.appendingPathComponent("test1.md")
        let file2 = memosDir.appendingPathComponent("test2.md")
        FileManager.default.createFile(atPath: file1.path, contents: nil)
        FileManager.default.createFile(atPath: file2.path, contents: nil)
        
        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)
        folder.reload()
        
        XCTAssertEqual(folder.currentMemos.count, 2)
    }
    
    func testFilterCurrentMemos() {
        let file1 = memosDir.appendingPathComponent("meeting.md")
        let file2 = memosDir.appendingPathComponent("notes.md")
        FileManager.default.createFile(atPath: file1.path, contents: nil)
        FileManager.default.createFile(atPath: file2.path, contents: nil)
        
        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)
        folder.reload()
        
        let filtered = folder.filteredCurrentMemos(searchText: "meeting")
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].name, "meeting.md")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme MemoViewer -only-testing MemoViewerTests/MemoFolderTests
```

Expected: `Build failed` (MemoFolder not yet defined)

- [ ] **Step 3: Implement MemoFolder**

```swift
// MemoViewer/Models/MemoFolder.swift
import Foundation
import Combine

class MemoFolder: ObservableObject {
    @Published var currentMemos: [MemoFile] = []
    @Published var archiveTree: [MemoTree] = []
    @Published var searchText: String = ""
    
    private let memosPath: URL
    private let archivePath: URL
    private var refreshTimer: Timer?
    
    init(memosPath: URL, archivePath: URL) {
        self.memosPath = memosPath
        self.archivePath = archivePath
        reload()
        startAutoRefresh()
    }
    
    func reload() {
        // Load current memos
        currentMemos = FileSystemHelper.scanMarkdownFiles(in: memosPath)
            .sorted { $0.creationDate > $1.creationDate }
        
        // Load archive hierarchy
        let archiveData = FileSystemHelper.scanHierarchical(in: archivePath)
        archiveTree = archiveData.map { yearData in
            let months = yearData.months.map { monthData in
                MonthNode(month: monthData.month, files: monthData.files)
            }
            return MemoTree(year: yearData.year, months: months)
        }
    }
    
    func filteredCurrentMemos(searchText: String) -> [MemoFile] {
        if searchText.isEmpty {
            return currentMemos
        }
        return currentMemos.filter { file in
            file.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    func filteredArchiveTree(searchText: String) -> [MemoTree] {
        if searchText.isEmpty {
            return archiveTree
        }
        
        return archiveTree.compactMap { yearNode in
            let filteredMonths = yearNode.months.compactMap { monthNode in
                let filteredFiles = monthNode.files.filter { file in
                    file.name.lowercased().contains(searchText.lowercased())
                }
                return filteredFiles.isEmpty ? nil : MonthNode(month: monthNode.month, files: filteredFiles)
            }
            return filteredMonths.isEmpty ? nil : MemoTree(year: yearNode.year, months: filteredMonths)
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.reload()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme MemoViewer -only-testing MemoViewerTests/MemoFolderTests
```

Expected: `Test Suite 'MemoFolderTests' passed`

- [ ] **Step 5: Commit**

```bash
git add MemoViewer/Models/MemoFolder.swift MemoViewerTests/MemoFolderTests.swift
git commit -m "feat: add MemoFolder with file scanning and auto-refresh"
```

---

## Task 6: SearchField Component

**Files:**
- Create: `MemoViewer/Views/SearchField.swift`

- [ ] **Step 1: Implement SearchField**

```swift
// MemoViewer/Views/SearchField.swift
import SwiftUI

struct SearchField: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search memos...", text: $text)
                .textFieldStyle(.roundedBorder)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct SearchField_Previews: PreviewProvider {
    static var previews: some View {
        SearchField(text: .constant(""))
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MemoViewer/Views/SearchField.swift
git commit -m "feat: add SearchField component"
```

---

## Task 7: CurrentMemosView

**Files:**
- Create: `MemoViewer/Views/CurrentMemosView.swift`

- [ ] **Step 1: Implement CurrentMemosView**

```swift
// MemoViewer/Views/CurrentMemosView.swift
import SwiftUI

struct CurrentMemosView: View {
    @ObservedObject var memoFolder: MemoFolder
    @State private var searchText: String = ""
    @State private var selectedFile: MemoFile?
    
    var filteredMemos: [MemoFile] {
        memoFolder.filteredCurrentMemos(searchText: searchText)
    }
    
    var body: some View {
        VStack {
            SearchField(text: $searchText)
            
            if filteredMemos.isEmpty {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No memos found")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredMemos) { memo in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memo.displayName)
                            .font(.body)
                        Text(dateFormatter.string(from: memo.creationDate))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .onDoubleClick {
                        openFile(memo)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func openFile(_ memo: MemoFile) {
        let workspace = NSWorkspace.shared
        do {
            try workspace.open(memo.url, withAppBundleIdentifier: "com.one-markdown.app")
        } catch {
            showErrorAlert(message: "One Markdown app not found. Please install it and try again.")
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture(count: 2, perform: action)
    }
}

struct CurrentMemosView_Previews: PreviewProvider {
    static var previews: some View {
        let folder = MemoFolder(
            memosPath: FileManager.default.temporaryDirectory,
            archivePath: FileManager.default.temporaryDirectory
        )
        CurrentMemosView(memoFolder: folder)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MemoViewer/Views/CurrentMemosView.swift
git commit -m "feat: add CurrentMemosView with list and double-click opening"
```

---

## Task 8: ArchiveView

**Files:**
- Create: `MemoViewer/Views/ArchiveView.swift`

- [ ] **Step 1: Implement ArchiveView**

```swift
// MemoViewer/Views/ArchiveView.swift
import SwiftUI

struct ArchiveView: View {
    @ObservedObject var memoFolder: MemoFolder
    @State private var searchText: String = ""
    
    var filteredTree: [MemoTree] {
        memoFolder.filteredArchiveTree(searchText: searchText)
    }
    
    var body: some View {
        VStack {
            SearchField(text: $searchText)
            
            if filteredTree.isEmpty {
                VStack {
                    Image(systemName: "archivebox")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No archived memos found")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredTree) { yearNode in
                    Section(header: Text(yearNode.year)) {
                        ForEach(yearNode.months) { monthNode in
                            DisclosureGroup(monthNode.month) {
                                ForEach(monthNode.files) { file in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(file.displayName)
                                            .font(.body)
                                        Text(dateFormatter.string(from: file.creationDate))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .onDoubleClick {
                                        openFile(file)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func openFile(_ memo: MemoFile) {
        let workspace = NSWorkspace.shared
        do {
            try workspace.open(memo.url, withAppBundleIdentifier: "com.one-markdown.app")
        } catch {
            showErrorAlert(message: "One Markdown app not found. Please install it and try again.")
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ArchiveView_Previews: PreviewProvider {
    static var previews: some View {
        let folder = MemoFolder(
            memosPath: FileManager.default.temporaryDirectory,
            archivePath: FileManager.default.temporaryDirectory
        )
        ArchiveView(memoFolder: folder)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MemoViewer/Views/ArchiveView.swift
git commit -m "feat: add ArchiveView with hierarchical year/month structure"
```

---

## Task 9: ContentView (Tab Container)

**Files:**
- Create: `MemoViewer/Views/ContentView.swift`

- [ ] **Step 1: Implement ContentView**

```swift
// MemoViewer/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var memoFolder: MemoFolder
    
    init(memosPath: URL, archivePath: URL) {
        _memoFolder = StateObject(wrappedValue: MemoFolder(memosPath: memosPath, archivePath: archivePath))
    }
    
    var body: some View {
        TabView {
            CurrentMemosView(memoFolder: memoFolder)
                .tabItem {
                    Label("Current", systemImage: "doc.text")
                }
            
            ArchiveView(memoFolder: memoFolder)
                .tabItem {
                    Label("Archive", systemImage: "archivebox")
                }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let tempDir = FileManager.default.temporaryDirectory
        ContentView(memosPath: tempDir, archivePath: tempDir)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MemoViewer/Views/ContentView.swift
git commit -m "feat: add ContentView with tab interface"
```

---

## Task 10: App Entry Point & Window Management

**Files:**
- Modify: `MemoViewer/MemoViewerApp.swift`

- [ ] **Step 1: Implement MemoViewerApp with window management**

```swift
// MemoViewer/MemoViewerApp.swift
import SwiftUI

@main
struct MemoViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            let memosPath = homeDir.appendingPathComponent(".openclaw/workspace/memos")
            let archivePath = homeDir.appendingPathComponent(".openclaw/workspace/memos-archive")
            
            ContentView(memosPath: memosPath, archivePath: archivePath)
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        if let frame = UserDefaults.standard.value(forKey: "windowFrame") as? String {
                            let components = frame.split(separator: ",").compactMap { Double($0) }
                            if components.count == 4 {
                                window.setFrame(
                                    NSRect(x: components[0], y: components[1], width: components[2], height: components[3]),
                                    display: true
                                )
                            }
                        } else {
                            window.setFrame(NSRect(x: 0, y: 0, width: 800, height: 600), display: true)
                        }
                        
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowResizabilityContentSize()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            let frame = window.frame
            let frameString = "\(frame.origin.x),\(frame.origin.y),\(frame.width),\(frame.height)"
            UserDefaults.standard.set(frameString, forKey: "windowFrame")
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add MemoViewer/MemoViewerApp.swift
git commit -m "feat: add app entry point with window persistence"
```

---

## Task 11: Integration Testing

**Files:**
- Test: `MemoViewerTests/IntegrationTests.swift`

- [ ] **Step 1: Write integration test**

```swift
// MemoViewerTests/IntegrationTests.swift
import XCTest
@testable import MemoViewer

class IntegrationTests: XCTestCase {
    
    var testDir: URL!
    var memosDir: URL!
    var archiveDir: URL!
    
    override func setUp() {
        super.setUp()
        testDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        memosDir = testDir.appendingPathComponent("memos")
        archiveDir = testDir.appendingPathComponent("memos-archive")
        try? FileManager.default.createDirectory(at: memosDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: testDir)
        super.tearDown()
    }
    
    func testFullWorkflow() {
        // Setup
        let file1 = memosDir.appendingPathComponent("note1.md")
        let file2 = memosDir.appendingPathComponent("note2.md")
        FileManager.default.createFile(atPath: file1.path, contents: "test".data(using: .utf8))
        FileManager.default.createFile(atPath: file2.path, contents: "test".data(using: .utf8))
        
        // Create archive structure
        let year2024 = archiveDir.appendingPathComponent("2024")
        let month01 = year2024.appendingPathComponent("01")
        try? FileManager.default.createDirectory(at: month01, withIntermediateDirectories: true)
        
        let archiveFile = month01.appendingPathComponent("old-note.md")
        FileManager.default.createFile(atPath: archiveFile.path, contents: "test".data(using: .utf8))
        
        // Test
        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)
        
        XCTAssertEqual(folder.currentMemos.count, 2)
        XCTAssertEqual(folder.archiveTree.count, 1)
        XCTAssertEqual(folder.archiveTree[0].year, "2024")
        XCTAssertEqual(folder.archiveTree[0].months.count, 1)
        XCTAssertEqual(folder.archiveTree[0].months[0].month, "01")
        XCTAssertEqual(folder.archiveTree[0].months[0].files.count, 1)
        
        // Test search
        let filtered = folder.filteredCurrentMemos(searchText: "note1")
        XCTAssertEqual(filtered.count, 1)
    }
}
```

- [ ] **Step 2: Run all tests**

```bash
xcodebuild test -scheme MemoViewer
```

Expected: `All tests passed`

- [ ] **Step 3: Commit**

```bash
git add MemoViewerTests/IntegrationTests.swift
git commit -m "test: add integration tests for full workflow"
```

---

## Task 12: Documentation

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

## Task 13: Build & Validate

**Files:**
- All created files

- [ ] **Step 1: Clean build**

```bash
xcodebuild clean -scheme MemoViewer
xcodebuild build -scheme MemoViewer
```

Expected: `Build succeeded`

- [ ] **Step 2: Run all tests**

```bash
xcodebuild test -scheme MemoViewer
```

Expected: `All tests passed`

- [ ] **Step 3: Run the app manually**

```bash
xcodebuild -scheme MemoViewer -configuration Release
# Then launch from Xcode or Finder
```

Verify:
- App launches without crashing
- Both tabs visible
- Search field works
- Files display with correct dates
- No files shown if folders are empty
- Auto-refresh works (create a test .md file while app is open)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "build: verify build and tests pass"
```

---

## Success Criteria Verification

- ✅ User can launch app and see both Current Memos and Archive tabs
- ✅ Clicking search field filters list instantly
- ✅ Double-clicking a file opens it in One Markdown.app (if installed)
- ✅ New files appear in the list within 2-3 seconds of being created
- ✅ App stays open and usable across multiple file operations
- ✅ App handles missing/invalid folders gracefully
- ✅ Window size/position remembered on next launch

---

## Implementation Summary

This plan implements a complete native macOS app with:
- Modular architecture (Models, Views, Utilities)
- Comprehensive test coverage
- Auto-refresh on a 2.5-second timer
- Hierarchical archive display (Year → Month → Files)
- Client-side search filtering
- Window position/size persistence
- Error handling for missing files and apps
- No external dependencies (pure Swift + SwiftUI + Foundation)

Total estimated time: 3-4 hours for an experienced Swift developer.
