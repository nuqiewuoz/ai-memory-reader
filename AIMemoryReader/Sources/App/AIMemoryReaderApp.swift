import SwiftUI

extension Notification.Name {
    static let editorManualSave = Notification.Name("editorManualSave")
    static let exportPDF = Notification.Name("exportPDF")
}

@main
struct AIMemoryReaderApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    appState.handleURL(url)
                }
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open File or Folder…") {
                    appState.openFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .textEditing) {
                Button("Find…") {
                    appState.focusSearch = true
                }
                .keyboardShortcut("f", modifiers: .command)
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .editorManualSave, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Divider()

                Button("Export PDF…") {
                    NotificationCenter.default.post(name: .exportPDF, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
            }

            CommandGroup(after: .sidebar) {
                Button("OpenClaw Source") {
                    if let source = appState.availableSources.first(where: { $0.id == "openclaw" }) {
                        appState.selectSource(source)
                    }
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Open Local Files…") {
                    appState.openFolder()
                }
                .keyboardShortcut("2", modifiers: .command)
            }
        }
        #endif
    }
}
