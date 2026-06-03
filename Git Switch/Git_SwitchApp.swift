import SwiftUI

@main
struct Git_SwitchApp: App {
    @StateObject private var manager = GitManager()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        // Single-instance management window. As a menu-bar (LSUIElement) utility it does
        // NOT open at launch (.defaultLaunchBehavior(.suppressed)) — the menu bar is the
        // home base; "Open App" / openWindow(id: "main") shows it on demand.
        Window("Git Switch", id: "main") {
            ContentView(manager: manager, themeManager: themeManager)
                .onAppear { themeManager.applyAppearance() }
                .onChange(of: themeManager.appearanceMode) { _, _ in
                    themeManager.applyAppearance()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)   // respect the 600x500 min but allow enlarging
        .defaultSize(width: 720, height: 600)
        .defaultLaunchBehavior(.suppressed)
        .commands { CommandGroup(replacing: .newItem) {} }

        // Standard Settings scene — opened via the gear (openSettings); a proper
        // preferences window rather than a hand-rolled modal sheet.
        Settings {
            SettingsView(themeManager: themeManager)
                .onAppear { themeManager.applyAppearance() }
                .onChange(of: themeManager.appearanceMode) { _, _ in
                    themeManager.applyAppearance()
                }
        }

        MenuBarExtra {
            MenuBarView(manager: manager, themeManager: themeManager)
        } label: {
            Image(systemName: "arrow.triangle.branch")
        }
        .menuBarExtraStyle(.window)
    }
}
