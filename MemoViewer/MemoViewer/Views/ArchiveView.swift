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

extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture(count: 2, perform: action)
    }
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
