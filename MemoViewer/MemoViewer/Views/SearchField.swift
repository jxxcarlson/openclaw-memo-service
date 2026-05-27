// MemoViewer/Views/SearchField.swift
import SwiftUI

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search memos...", text: $text)
                .textFieldStyle(.roundedBorder)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct SearchField_Previews: PreviewProvider {
    static var previews: some View {
        SearchField(text: .constant(""))
    }
}
