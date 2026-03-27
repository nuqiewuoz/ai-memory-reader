import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // AI Sources section
            aiSourcesSection

            Divider()

            // File tree
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
            Text("AI Memory Reader")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var aiSourcesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AI Sources")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ForEach(appState.availableSources) { source in
                AISourceRow(source: source, isSelected: appState.selectedSourceID == source.id)
                    .onTapGesture {
                        appState.selectSource(source)
                    }
            }

            // Local Files option
            HStack(spacing: 8) {
                Text("📂")
                    .font(.title3)
                Text("Local Files…")
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                appState.selectedSourceID == "local"
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 8)
            .onTapGesture {
                appState.openFolder()
            }

            if appState.availableSources.isEmpty {
                Text("No AI sources detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 8)
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
            Text("Select an AI source or ⌘O to open a folder")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AISourceRow: View {
    let source: AISource
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(source.icon)
                .font(.title3)
            Text(source.name)
                .font(.system(size: 13))
                .lineLimit(1)
            Spacer()
            if source.todayMemoryFile != nil {
                Circle()
                    .fill(source.color)
                    .frame(width: 8, height: 8)
                    .help("Today's memory file available")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(
            isSelected
                ? source.color.opacity(0.15)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 8)
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
                HStack {
                    Text(node.name)
                        .lineLimit(1)
                    if appState.todayFileNode == node {
                        Text("Today")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            } icon: {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
            }
            .tag(node)
        }
    }
}
