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
