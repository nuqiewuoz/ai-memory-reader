import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            if let root = appState.rootNode {
                List(selection: Bindable(appState).selectedFile) {
                    if let children = root.children {
                        ForEach(children) { node in
                            FileNodeView(node: node)
                        }
                    }
                }
                .listStyle(.sidebar)
            } else {
                emptyState
            }
        }
        .safeAreaInset(edge: .top) {
            headerView
        }
        .frame(minWidth: 220)
    }

    private var headerView: some View {
        HStack {
            if let rootURL = appState.rootURL {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                Text(rootURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
            } else {
                Text("AI Memory Reader")
                    .font(.headline)
            }
            Spacer()
            Button {
                appState.openFolder()
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .buttonStyle(.borderless)
            .help("Open Folder")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No folder opened")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("⌘O to open a folder")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FileNodeView: View {
    @Environment(AppState.self) private var appState
    let node: FileNode

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: Bindable(node).isExpanded) {
                if let children = node.children {
                    ForEach(children) { child in
                        FileNodeView(node: child)
                    }
                }
            } label: {
                Label(node.name, systemImage: "folder")
                    .foregroundColor(.primary)
            }
        } else {
            Label {
                Text(node.name)
                    .lineLimit(1)
            } icon: {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
            }
            .tag(node)
        }
    }
}
