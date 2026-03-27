import SwiftUI

@Observable
final class AppState {
    var rootNode: FileNode?
    var selectedFile: FileNode?
    var rootURL: URL?

    var availableSources: [AISource] = []
    var selectedSourceID: String? {
        didSet {
            UserDefaults.standard.set(selectedSourceID, forKey: "lastSelectedSourceID")
        }
    }

    /// Today's memory file node, if the current source has one
    var todayFileNode: FileNode?

    init() {
        availableSources = AISource.detectAvailable()
        selectedSourceID = UserDefaults.standard.string(forKey: "lastSelectedSourceID")
    }

    /// Called on launch to restore last source or pick the first available
    func restoreOrAutoSelect() {
        // Try to restore the saved source
        if let savedID = selectedSourceID,
           let source = availableSources.first(where: { $0.id == savedID }) {
            selectSource(source)
            return
        }

        // Fallback: pick first available source
        if let first = availableSources.first {
            selectSource(first)
            return
        }
    }

    func selectSource(_ source: AISource) {
        selectedSourceID = source.id
        loadDirectory(source.url)
        autoSelectTodayFile(for: source)
    }

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing markdown files"
        panel.prompt = "Open"

        if panel.runModal() == .OK, let url = panel.url {
            selectedSourceID = "local"
            UserDefaults.standard.set(url.path(percentEncoded: false), forKey: "lastLocalFolderPath")
            loadDirectory(url)
        }
    }

    func loadDirectory(_ url: URL) {
        rootURL = url
        rootNode = FileTreeBuilder.buildTree(at: url)
        rootNode?.isExpanded = true
        selectedFile = nil
        todayFileNode = nil
    }

    /// If the source has a memory/YYYY-MM-DD.md for today, find it in the tree and highlight it
    private func autoSelectTodayFile(for source: AISource) {
        guard let todayURL = source.todayMemoryFile else { return }
        if let node = findNode(url: todayURL, in: rootNode) {
            todayFileNode = node
            // Expand parent directories to make it visible
            expandPathTo(node: node)
            selectedFile = node
        }
    }

    private func findNode(url: URL, in node: FileNode?) -> FileNode? {
        guard let node else { return nil }
        if node.url == url { return node }
        if let children = node.children {
            for child in children {
                if let found = findNode(url: url, in: child) {
                    return found
                }
            }
        }
        return nil
    }

    private func expandPathTo(node: FileNode) {
        guard let root = rootNode else { return }
        _ = expandPathTo(target: node.url, in: root)
    }

    @discardableResult
    private func expandPathTo(target: URL, in node: FileNode) -> Bool {
        if node.url == target { return true }
        if let children = node.children {
            for child in children {
                if expandPathTo(target: target, in: child) {
                    node.isExpanded = true
                    return true
                }
            }
        }
        return false
    }
}
