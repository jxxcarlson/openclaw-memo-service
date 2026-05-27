import Foundation

class FileSystemHelper {
    static func scanMarkdownFiles(in folder: URL) -> [MemoFile] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey]
            )

            let markdownFiles = contents.filter { url in
                let isHidden = url.lastPathComponent.hasPrefix(".")
                let isMarkdown = url.pathExtension.lowercased() == "md"
                return !isHidden && isMarkdown
            }

            return markdownFiles.compactMap { url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.creationDateKey])
                    let creationDate = resourceValues.creationDate ?? Date()

                    return MemoFile(
                        url: url,
                        name: url.lastPathComponent,
                        creationDate: creationDate
                    )
                } catch {
                    return nil
                }
            }
        } catch {
            // Folder doesn't exist or is inaccessible
            return []
        }
    }

    static func scanHierarchical(in folder: URL) -> [(year: String, months: [(month: String, files: [MemoFile])])] {
        do {
            let yearFolders = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil
            ).filter { url in
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                return isDir.boolValue && !url.lastPathComponent.hasPrefix(".")
            }

            return yearFolders.sorted { $0.lastPathComponent > $1.lastPathComponent }.compactMap { yearURL in
                let year = yearURL.lastPathComponent

                do {
                    let monthFolders = try FileManager.default.contentsOfDirectory(
                        at: yearURL,
                        includingPropertiesForKeys: nil
                    ).filter { url in
                        var isDir: ObjCBool = false
                        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                        return isDir.boolValue && !url.lastPathComponent.hasPrefix(".")
                    }

                    let months = monthFolders.sorted { $0.lastPathComponent > $1.lastPathComponent }.compactMap { monthURL in
                        let month = monthURL.lastPathComponent
                        let files = scanMarkdownFiles(in: monthURL).sorted { $0.creationDate > $1.creationDate }
                        return (month: month, files: files)
                    }

                    return (year: year, months: months)
                } catch {
                    return nil
                }
            }
        } catch {
            return []
        }
    }
}
