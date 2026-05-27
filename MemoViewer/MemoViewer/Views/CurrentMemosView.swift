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
