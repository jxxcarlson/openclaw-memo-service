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
        // Setup - create current memo files
        let file1 = memosDir.appendingPathComponent("note1.md")
        let file2 = memosDir.appendingPathComponent("note2.md")
        FileManager.default.createFile(atPath: file1.path, contents: "test".data(using: .utf8))
        FileManager.default.createFile(atPath: file2.path, contents: "test".data(using: .utf8))

        // Create archive structure
        let year2024 = archiveDir.appendingPathComponent("2024")
        let month01 = year2024.appendingPathComponent("01")
        try? FileManager.default.createDirectory(at: month01, withIntermediateDirectories: true)

        let archiveFile = month01.appendingPathComponent("old-note.md")
        FileManager.default.createFile(atPath: archiveFile.path, contents: "archived content".data(using: .utf8))

        // Test - create MemoFolder and verify it loads both current and archive
        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Verify current memos
        XCTAssertEqual(folder.currentMemos.count, 2, "Should have 2 current memos")
        XCTAssertTrue(folder.currentMemos.contains { $0.name == "note1.md" }, "Should contain note1.md")
        XCTAssertTrue(folder.currentMemos.contains { $0.name == "note2.md" }, "Should contain note2.md")

        // Verify archive structure
        XCTAssertEqual(folder.archiveTree.count, 1, "Should have 1 year in archive")
        XCTAssertEqual(folder.archiveTree[0].year, "2024", "Should have year 2024")
        XCTAssertEqual(folder.archiveTree[0].months.count, 1, "Should have 1 month in 2024")
        XCTAssertEqual(folder.archiveTree[0].months[0].month, "01", "Should have month 01")
        XCTAssertEqual(folder.archiveTree[0].months[0].files.count, 1, "Should have 1 file in month 01")
        XCTAssertEqual(folder.archiveTree[0].months[0].files[0].name, "old-note.md", "Archive file should be named old-note.md")
    }

    func testSearchFilteringCurrentMemos() {
        // Setup - create memos with different names
        let meetingFile = memosDir.appendingPathComponent("meeting-notes.md")
        let projectFile = memosDir.appendingPathComponent("project-plan.md")
        let dailyFile = memosDir.appendingPathComponent("daily-standup.md")

        FileManager.default.createFile(atPath: meetingFile.path, contents: "meeting content".data(using: .utf8))
        FileManager.default.createFile(atPath: projectFile.path, contents: "project content".data(using: .utf8))
        FileManager.default.createFile(atPath: dailyFile.path, contents: "daily content".data(using: .utf8))

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Test exact match
        let meetingFiltered = folder.filteredCurrentMemos(searchText: "meeting")
        XCTAssertEqual(meetingFiltered.count, 1, "Should find 1 memo with 'meeting'")
        XCTAssertEqual(meetingFiltered[0].name, "meeting-notes.md", "Should find meeting-notes.md")

        // Test partial match
        let projectFiltered = folder.filteredCurrentMemos(searchText: "project")
        XCTAssertEqual(projectFiltered.count, 1, "Should find 1 memo with 'project'")

        // Test case-insensitive search
        let caseInsensitiveFiltered = folder.filteredCurrentMemos(searchText: "MEETING")
        XCTAssertEqual(caseInsensitiveFiltered.count, 1, "Should be case-insensitive")

        // Test empty search returns all
        let allFiltered = folder.filteredCurrentMemos(searchText: "")
        XCTAssertEqual(allFiltered.count, 3, "Empty search should return all memos")

        // Test no match
        let noMatch = folder.filteredCurrentMemos(searchText: "nonexistent")
        XCTAssertEqual(noMatch.count, 0, "Should return 0 memos for non-matching search")
    }

    func testSearchFilteringArchive() {
        // Setup - create archive structure with multiple years and months
        let year2024 = archiveDir.appendingPathComponent("2024")
        let year2023 = archiveDir.appendingPathComponent("2023")

        let month01_2024 = year2024.appendingPathComponent("01")
        let month02_2024 = year2024.appendingPathComponent("02")
        let month12_2023 = year2023.appendingPathComponent("12")

        try? FileManager.default.createDirectory(at: month01_2024, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: month02_2024, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: month12_2023, withIntermediateDirectories: true)

        // Add files with distinguishing names
        let file1 = month01_2024.appendingPathComponent("january-report.md")
        let file2 = month02_2024.appendingPathComponent("february-summary.md")
        let file3 = month12_2023.appendingPathComponent("december-notes.md")

        FileManager.default.createFile(atPath: file1.path, contents: "january".data(using: .utf8))
        FileManager.default.createFile(atPath: file2.path, contents: "february".data(using: .utf8))
        FileManager.default.createFile(atPath: file3.path, contents: "december".data(using: .utf8))

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Test search in archive
        let reportFiltered = folder.filteredArchiveTree(searchText: "report")
        XCTAssertEqual(reportFiltered.count, 1, "Should find 1 year with 'report'")
        XCTAssertEqual(reportFiltered[0].year, "2024", "Should be year 2024")
        XCTAssertEqual(reportFiltered[0].months.count, 1, "Should have 1 month with matching file")
        XCTAssertEqual(reportFiltered[0].months[0].files.count, 1, "Should have 1 matching file")

        // Test search across multiple years
        let allFiltered = folder.filteredArchiveTree(searchText: "")
        XCTAssertEqual(allFiltered.count, 2, "Should have 2 years")

        // Test empty filter returns all
        XCTAssertEqual(allFiltered[0].year, "2024", "First year should be 2024 (sorted descending)")
        XCTAssertEqual(allFiltered[0].months.count, 2, "2024 should have 2 months")
        XCTAssertEqual(allFiltered[1].year, "2023", "Second year should be 2023")

        // Test case-insensitive archive search
        let caseInsensitiveArchiveFiltered = folder.filteredArchiveTree(searchText: "SUMMARY")
        XCTAssertEqual(caseInsensitiveArchiveFiltered.count, 1, "Archive search should be case-insensitive")
        XCTAssertEqual(caseInsensitiveArchiveFiltered[0].months[0].files[0].name, "february-summary.md")
    }

    func testCurrentMemosAreSorted() {
        // Setup - create memos with different names
        let file1 = memosDir.appendingPathComponent("z-last.md")
        let file2 = memosDir.appendingPathComponent("a-first.md")
        let file3 = memosDir.appendingPathComponent("m-middle.md")

        FileManager.default.createFile(atPath: file1.path, contents: nil)
        // Add small delay to ensure different creation dates
        usleep(100)
        FileManager.default.createFile(atPath: file2.path, contents: nil)
        usleep(100)
        FileManager.default.createFile(atPath: file3.path, contents: nil)

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Verify memos are sorted by creation date (newest first)
        XCTAssertEqual(folder.currentMemos.count, 3)
        XCTAssertEqual(folder.currentMemos[0].name, "m-middle.md", "Most recent should be first")
        XCTAssertEqual(folder.currentMemos[2].name, "z-last.md", "Oldest should be last")
    }

    func testReloadUpdatesData() {
        // Setup - create initial memos
        let file1 = memosDir.appendingPathComponent("note1.md")
        FileManager.default.createFile(atPath: file1.path, contents: nil)

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)
        XCTAssertEqual(folder.currentMemos.count, 1)

        // Add a new memo
        let file2 = memosDir.appendingPathComponent("note2.md")
        FileManager.default.createFile(atPath: file2.path, contents: nil)

        // Reload and verify
        folder.reload()
        XCTAssertEqual(folder.currentMemos.count, 2, "Reload should update current memos")

        // Remove a memo
        try? FileManager.default.removeItem(at: file1)

        // Reload and verify
        folder.reload()
        XCTAssertEqual(folder.currentMemos.count, 1, "Reload should reflect deletions")
        XCTAssertEqual(folder.currentMemos[0].name, "note2.md")
    }

    func testMixedCurrentAndArchiveMemos() {
        // Setup - create both current and archive memos simultaneously
        let currentFile1 = memosDir.appendingPathComponent("current-note1.md")
        let currentFile2 = memosDir.appendingPathComponent("current-note2.md")
        FileManager.default.createFile(atPath: currentFile1.path, contents: "current content 1".data(using: .utf8))
        FileManager.default.createFile(atPath: currentFile2.path, contents: "current content 2".data(using: .utf8))

        let year2024 = archiveDir.appendingPathComponent("2024")
        let month06 = year2024.appendingPathComponent("06")
        try? FileManager.default.createDirectory(at: month06, withIntermediateDirectories: true)

        let archiveFile1 = month06.appendingPathComponent("archived-note1.md")
        FileManager.default.createFile(atPath: archiveFile1.path, contents: "archived content".data(using: .utf8))

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Verify both current and archive are loaded
        XCTAssertEqual(folder.currentMemos.count, 2, "Should have 2 current memos")
        XCTAssertEqual(folder.archiveTree.count, 1, "Should have archive tree")
        XCTAssertEqual(folder.archiveTree[0].months[0].files.count, 1, "Should have archived memo")

        // Verify they are distinct
        let currentNames = folder.currentMemos.map { $0.name }
        XCTAssertTrue(currentNames.contains("current-note1.md"))
        XCTAssertTrue(currentNames.contains("current-note2.md"))
        XCTAssertFalse(currentNames.contains("archived-note1.md"))
    }

    func testEmptyDirectories() {
        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        XCTAssertEqual(folder.currentMemos.count, 0, "Empty memos dir should have no current memos")
        XCTAssertEqual(folder.archiveTree.count, 0, "Empty archive dir should have no archive")
    }

    func testHiddenFilesIgnored() {
        // Setup - create hidden and visible files
        let visibleFile = memosDir.appendingPathComponent("visible.md")
        let hiddenFile = memosDir.appendingPathComponent(".hidden.md")
        FileManager.default.createFile(atPath: visibleFile.path, contents: nil)
        FileManager.default.createFile(atPath: hiddenFile.path, contents: nil)

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Verify only visible file is loaded
        XCTAssertEqual(folder.currentMemos.count, 1, "Should ignore hidden files")
        XCTAssertEqual(folder.currentMemos[0].name, "visible.md")
    }

    func testNonMarkdownFilesIgnored() {
        // Setup - create various file types
        let markdownFile = memosDir.appendingPathComponent("note.md")
        let textFile = memosDir.appendingPathComponent("readme.txt")
        let pdfFile = memosDir.appendingPathComponent("document.pdf")

        FileManager.default.createFile(atPath: markdownFile.path, contents: nil)
        FileManager.default.createFile(atPath: textFile.path, contents: nil)
        FileManager.default.createFile(atPath: pdfFile.path, contents: nil)

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Verify only markdown file is loaded
        XCTAssertEqual(folder.currentMemos.count, 1, "Should only load .md files")
        XCTAssertEqual(folder.currentMemos[0].name, "note.md")
    }

    func testMemoFileAttributes() {
        // Setup
        let file = memosDir.appendingPathComponent("test-memo.md")
        FileManager.default.createFile(atPath: file.path, contents: "memo content".data(using: .utf8))

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)
        let memo = folder.currentMemos[0]

        // Verify memo attributes
        XCTAssertEqual(memo.name, "test-memo.md", "Name should match filename")
        XCTAssertEqual(memo.url, file, "URL should match file path")
        XCTAssertNotNil(memo.creationDate, "Should have creation date")
        XCTAssertEqual(memo.displayName, "test-memo", "Display name should remove .md extension")
    }

    func testArchiveStructureIntegrity() {
        // Setup - create complex archive structure
        let year2024 = archiveDir.appendingPathComponent("2024")
        let year2023 = archiveDir.appendingPathComponent("2023")

        let month01_2024 = year2024.appendingPathComponent("01")
        let month12_2024 = year2024.appendingPathComponent("12")
        let month06_2023 = year2023.appendingPathComponent("06")

        try? FileManager.default.createDirectory(at: month01_2024, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: month12_2024, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: month06_2023, withIntermediateDirectories: true)

        // Add files
        let file1 = month01_2024.appendingPathComponent("file1.md")
        let file2 = month12_2024.appendingPathComponent("file2.md")
        let file3 = month06_2023.appendingPathComponent("file3.md")

        FileManager.default.createFile(atPath: file1.path, contents: nil)
        FileManager.default.createFile(atPath: file2.path, contents: nil)
        FileManager.default.createFile(atPath: file3.path, contents: nil)

        let folder = MemoFolder(memosPath: memosDir, archivePath: archiveDir)

        // Verify archive structure
        XCTAssertEqual(folder.archiveTree.count, 2, "Should have 2 years")

        // Years should be sorted descending (2024 first)
        XCTAssertEqual(folder.archiveTree[0].year, "2024")
        XCTAssertEqual(folder.archiveTree[1].year, "2023")

        // 2024 should have 2 months (sorted descending)
        XCTAssertEqual(folder.archiveTree[0].months.count, 2)
        XCTAssertEqual(folder.archiveTree[0].months[0].month, "12")
        XCTAssertEqual(folder.archiveTree[0].months[1].month, "01")

        // 2023 should have 1 month
        XCTAssertEqual(folder.archiveTree[1].months.count, 1)
        XCTAssertEqual(folder.archiveTree[1].months[0].month, "06")
    }
}
