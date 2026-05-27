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
