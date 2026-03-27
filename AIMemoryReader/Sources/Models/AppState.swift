import SwiftUI

@Observable
final class AppState {
    var rootNode: FileNode?
    var selectedFile: FileNode?
    var rootURL: URL?

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing markdown files"
        panel.prompt = "Open"

        if panel.runModal() == .OK, let url = panel.url {
            loadDirectory(url)
        }
    }

    func loadDirectory(_ url: URL) {
        rootURL = url
        rootNode = FileTreeBuilder.buildTree(at: url)
        rootNode?.isExpanded = true
        selectedFile = nil
    }
}
