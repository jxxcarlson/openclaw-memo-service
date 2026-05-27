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
