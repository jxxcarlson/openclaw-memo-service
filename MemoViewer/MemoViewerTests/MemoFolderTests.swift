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
