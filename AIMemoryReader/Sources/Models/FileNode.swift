import Foundation

@Observable
final class FileNode: Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?
    var isExpanded: Bool = false

    static let supportedExtensions: Set<String> = ["md", "json"]

    var isMarkdown: Bool { url.pathExtension.lowercased() == "md" }
    var isJSON: Bool { url.pathExtension.lowercased() == "json" }

    static func isSupportedFile(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.id = url.path(percentEncoded: false)
        self.name = url.lastPathComponent
        self.url = url
        self.isDirectory = isDirectory
        self.children = children
    }

    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
