import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            if appState.rootNode == nil {
                appState.restoreOrAutoSelect()
            }
        }
        .onChange(of: appState.isSingleFileMode) { _, isSingle in
            columnVisibility = isSingle ? .detailOnly : .automatic
        }
    }
}
