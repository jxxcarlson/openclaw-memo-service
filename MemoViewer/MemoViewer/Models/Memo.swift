import Foundation

struct Memo: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let filePath: String
    let dateCreated: Date
    let dateModified: Date
    let isArchived: Bool

    init(
        title: String,
        content: String,
        filePath: String,
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.filePath = filePath
        self.dateCreated = Date()
        self.dateModified = Date()
        self.isArchived = isArchived
    }
}
