import SwiftUI

struct ContentView: View {
    @StateObject private var memoFolder: MemoFolder

    init(memosPath: URL, archivePath: URL) {
        _memoFolder = StateObject(wrappedValue: MemoFolder(memosPath: memosPath, archivePath: archivePath))
    }

    var body: some View {
        TabView {
            CurrentMemosView(memoFolder: memoFolder)
                .tabItem {
                    Label("Current", systemImage: "doc.text")
                }

            ArchiveView(memoFolder: memoFolder)
                .tabItem {
                    Label("Archive", systemImage: "archivebox")
                }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let tempDir = FileManager.default.temporaryDirectory
        ContentView(memosPath: tempDir, archivePath: tempDir)
    }
}
