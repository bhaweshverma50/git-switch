import SwiftUI

@main
struct Git_SwitchApp: App {
    @StateObject private var manager = GitManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        // A single-instance Window (not WindowGroup) with a stable id so the menu bar
        // can reliably reopen/focus it via openWindow(id:) — even after it's closed —
        // without ever spawning duplicate windows.
        Window("Git Switch", id: "main") {
            ContentView(manager: manager, themeManager: themeManager)
                .onAppear { themeManager.applyAppearance() }
                .onChange(of: themeManager.appearanceMode) { _, _ in
                    themeManager.applyAppearance()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        MenuBarExtra {
            MenuBarView(manager: manager, themeManager: themeManager)
        } label: {
            Image(systemName: "arrow.triangle.branch")
        }
        .menuBarExtraStyle(.window)
    }
}
