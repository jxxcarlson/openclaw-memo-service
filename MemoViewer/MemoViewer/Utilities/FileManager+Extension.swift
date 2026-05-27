import Foundation

extension FileManager {
    func contentsOfMarkdownDirectory(at path: String) throws -> [URL] {
        let contents = try contentsOfDirectory(atPath: path)
        return contents
            .filter { $0.hasSuffix(".md") }
            .map { URL(fileURLWithPath: (path as NSString).appendingPathComponent($0)) }
    }
}
