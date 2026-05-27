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
