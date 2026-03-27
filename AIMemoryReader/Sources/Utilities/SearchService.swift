import Foundation

struct SearchResult: Identifiable {
    let id = UUID()
    let fileNode: FileNode
    let matchedLine: String
    let lineNumber: Int
}

enum SearchService {
    /// Search within a single file for all matching lines (find-in-file)
    static func searchInFile(query: String, fileURL: URL) -> [SearchResult] {
        guard !query.isEmpty else { return [] }

        let lowercasedQuery = query.lowercased()
        var results: [SearchResult] = []

        guard let data = try? Data(contentsOf: fileURL),
              let content = String(data: data, encoding: .utf8)
        else { return [] }

        let lines = content.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            if line.lowercased().contains(lowercasedQuery) {
                let node = FileNode(url: fileURL, isDirectory: false)
                results.append(SearchResult(
                    fileNode: node,
                    matchedLine: line.trimmingCharacters(in: .whitespaces),
                    lineNumber: index + 1
                ))
            }
        }

        return results
    }

    /// Search all .md files under a root URL for the given query
    static func search(query: String, in rootURL: URL) -> [SearchResult] {
        guard !query.isEmpty else { return [] }

        let fm = FileManager.default
        var results: [SearchResult] = []
        let lowercasedQuery = query.lowercased()

        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "md" else { continue }

            guard let data = try? Data(contentsOf: fileURL),
                  let content = String(data: data, encoding: .utf8)
            else { continue }

            let lines = content.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if line.lowercased().contains(lowercasedQuery) {
                    let node = FileNode(url: fileURL, isDirectory: false)
                    results.append(SearchResult(
                        fileNode: node,
                        matchedLine: line.trimmingCharacters(in: .whitespaces),
                        lineNumber: index + 1
                    ))
                    // Only take first match per file to keep results manageable
                    break
                }
            }
        }

        return results
    }
}
