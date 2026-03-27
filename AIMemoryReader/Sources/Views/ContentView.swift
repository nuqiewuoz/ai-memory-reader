import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            // Auto-load a default AI memory directory if available
            if appState.rootNode == nil {
                let homeDir = FileManager.default.homeDirectoryForCurrentUser
                let openclawWorkspace = homeDir.appendingPathComponent(".openclaw/workspace")
                if FileManager.default.fileExists(atPath: openclawWorkspace.path) {
                    appState.loadDirectory(openclawWorkspace)
                }
            }
        }
    }
}
