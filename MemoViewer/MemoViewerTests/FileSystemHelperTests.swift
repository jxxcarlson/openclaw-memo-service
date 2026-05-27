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
