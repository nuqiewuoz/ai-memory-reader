import SwiftUI

@main
struct AIMemoryReaderApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder…") {
                    appState.openFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
