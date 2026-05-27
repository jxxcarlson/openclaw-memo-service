import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Welcome to MemoViewer")
                .font(.title)
            Text("Your markdown memos viewer")
                .font(.subtitle)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
