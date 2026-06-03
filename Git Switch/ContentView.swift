import SwiftUI
import AppKit
import Combine

// MARK: - MENU BAR VIEW

struct MenuBarView: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.openWindow) private var openWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var refreshRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(themeManager.accentColor)
                        .frame(width: 24, height: 24)
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(themeManager.accentForeground)
                }
                
                Text("Git Switch")
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    if !reduceMotion {
                        withAnimation(.linear(duration: 0.6)) { refreshRotation += 360 }
                    }
                    manager.refreshAll()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(refreshRotation), anchor: .center)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Refresh")
                .help("Refresh")
                .disabled(manager.isLoading)
                .opacity(manager.isLoading ? 0.5 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            
            Divider()
            
            // Global Identity
            MenuBarGlobalIdentity(manager: manager, themeManager: themeManager)
                .padding(12)
            
            if !manager.profiles.isEmpty {
                Divider()
                
                // Profiles
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(manager.profiles) { profile in
                            MenuBarProfileRow(profile: profile, manager: manager, themeManager: themeManager)
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 260)
            }
            
            Divider()
            
            // Footer Actions
            HStack(spacing: 8) {
                Button(action: openMainWindow) {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 11))
                        Text("Open App")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Quit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "main")
    }
}

struct MenuBarGlobalIdentity: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 32, height: 32)
                Text(initials)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.accentForeground)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Global Identity")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(manager.globalName.isEmpty ? "Not configured" : manager.globalName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(manager.globalEmail.isEmpty ? "—" : manager.globalEmail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
    
    var initials: String {
        let name = manager.globalName.isEmpty ? "?" : manager.globalName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct MenuBarProfileRow: View {
    let profile: GitProfile
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @State private var isCopied = false
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(themeManager.accentColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(profile.folder)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Button(action: copyKey) {
                Image(systemName: isCopied ? "checkmark" : "key.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isCopied ? .green : .secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(isCopied ? "Copied" : "Copy SSH key")
            .help("Copy SSH Key")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    private func copyKey() {
        if manager.copySSHKey(for: profile) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { isCopied = false }
            }
        }
    }
}

// MARK: - LOGIC LAYER
// `Shell` lives in Shell.swift — it runs executables via argv (no shell), so user
// input can never be interpreted as shell syntax.

struct GitProfile: Identifiable, Equatable {
    var folder: String
    var name: String
    var email: String
    var configPath: String
    var includeBlock: String
    // Stable identity derived from durable data (configPath is unique per profile),
    // so SwiftUI diffing/animations and sheet(item:) survive a refresh.
    var id: String { configPath }
}

class GitManager: ObservableObject {
    @Published var profiles: [GitProfile] = []
    @Published var globalName: String = ""
    @Published var globalEmail: String = ""
    @Published var isLoading = false
    /// Set when a write/operation fails; surfaced as an alert so failures aren't silent.
    @Published var lastError: String?

    private let globalConfigPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gitconfig").path
    private let sshDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh").path

    init() { refreshAll() }

    private func reportError(_ message: String) {
        DispatchQueue.main.async { self.lastError = message }
    }
    
    func refreshAll() {
        withAnimation(.easeOut(duration: 0.2)) { isLoading = true }
        DispatchQueue.global(qos: .userInitiated).async {
            // Heal any pre-existing config whose includeIf blocks are in the wrong
            // (creation) order so the most specific folder wins.
            self.normalizeGlobalConfigOrder()
            let gName = Shell.run("git", ["config", "--global", "user.name"])
            let gEmail = Shell.run("git", ["config", "--global", "user.email"])
            let loadedProfiles = self.fetchProfiles()
            
            DispatchQueue.main.async {
                self.globalName = gName
                self.globalEmail = gEmail
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.profiles = loadedProfiles
                    self.isLoading = false
                }
            }
        }
    }

    func saveGlobalConfig(name: String, email: String) {
        Shell.run("git", ["config", "--global", "user.name", name])
        Shell.run("git", ["config", "--global", "user.email", email])
        refreshAll()
    }

    private func fetchProfiles() -> [GitProfile] {
        guard let content = try? String(contentsOfFile: globalConfigPath, encoding: .utf8) else { return [] }
        return parseIncludeBlocks(in: content).map { parsed in
            let details = readProfileDetails(path: parsed.configPath)
            return GitProfile(folder: parsed.folder, name: details.name, email: details.email,
                              configPath: parsed.configPath, includeBlock: parsed.block)
        }
    }

    private func readProfileDetails(path: String) -> (name: String, email: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedPath) else { return ("Missing config", "—") }
        // Read via git's own parser instead of substring matching — robust to formatting.
        let name = Shell.run("git", ["config", "-f", expandedPath, "user.name"])
        let email = Shell.run("git", ["config", "-f", expandedPath, "user.email"])
        return (name.isEmpty ? "Unknown" : name, email.isEmpty ? "Unknown" : email)
    }

    /// Creates a new context profile. `completion` is called on the main thread with
    /// `nil` on success, or a user-facing error message on failure.
    func createProfile(name: String, email: String, folder: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async {
            // Resolve symlinks / ~ / .. and strip trailing slashes so the gitdir pattern
            // matches the path Git actually tests (e.g. /tmp -> /private/tmp).
            let canonicalFolder = normalizeFolderPath(folder)
            let currentGlobal = (try? String(contentsOfFile: self.globalConfigPath, encoding: .utf8)) ?? ""

            // Reject a second profile for a folder that already has one — two includeIf
            // blocks for the same gitdir would just shadow each other (last-match-wins).
            if existingGitdirFolders(in: currentGlobal).contains(canonicalFolder) {
                DispatchQueue.main.async { completion("A profile for this folder already exists.") }
                return
            }

            // Filesystem-safe, unique base for the key + config filenames so two profiles
            // (e.g. "Work" and "work") can never overwrite each other's files.
            let home = FileManager.default.homeDirectoryForCurrentUser
            let slug = uniqueSlug(sanitizeProfileSlug(name)) { candidate in
                FileManager.default.fileExists(atPath: "\(self.sshDir)/id_ed25519_\(candidate)") ||
                FileManager.default.fileExists(atPath: home.appendingPathComponent(".gitconfig_\(candidate)").path)
            }
            let keyFile = "\(self.sshDir)/id_ed25519_\(slug)"
            let configPath = home.appendingPathComponent(".gitconfig_\(slug)").path

            // ~/.ssh must be 0700 or ssh refuses to use keys in it.
            if !FileManager.default.fileExists(atPath: self.sshDir) {
                try? FileManager.default.createDirectory(atPath: self.sshDir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            } else {
                try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: self.sshDir)
            }
            if !FileManager.default.fileExists(atPath: keyFile) {
                Shell.run("ssh-keygen", ["-t", "ed25519", "-C", email, "-f", keyFile, "-N", ""])
            }
            Shell.run("ssh-add", ["--apple-use-keychain", keyFile])

            self.writeLocalConfig(path: configPath, name: name, email: email, keyFile: keyFile)

            // Exactly one trailing slash, even if the user typed one.
            let includeDirective = "\n[includeIf \"gitdir:\(canonicalFolder)/\"]\n    path = \(configPath)\n"
            // Reorder so the most specific folder wins (Git applies all matching
            // includeIf blocks, last-match-wins) instead of relying on creation order.
            let newGlobal = reorderGitIncludeBlocks(in: currentGlobal + includeDirective)
            do {
                try newGlobal.write(toFile: self.globalConfigPath, atomically: true, encoding: .utf8)
            } catch {
                DispatchQueue.main.async { completion("Couldn't update ~/.gitconfig — check file permissions.") }
                return
            }

            DispatchQueue.main.async { self.refreshAll(); completion(nil) }
        }
    }
    
    func updateProfile(profile: GitProfile, newName: String, newEmail: String) {
        DispatchQueue.global().async {
            let expandedPath = NSString(string: profile.configPath).expandingTildeInPath
            // Use git's own writer so [core] sshCommand and any other keys are preserved
            // (the old code rewrote the whole file and could blank out the SSH key).
            Shell.run("git", ["config", "-f", expandedPath, "user.name", newName])
            Shell.run("git", ["config", "-f", expandedPath, "user.email", newEmail])
            DispatchQueue.main.async { self.refreshAll() }
        }
    }

    func deleteProfile(_ profile: GitProfile) {
        DispatchQueue.global().async {
            if let currentGlobal = try? String(contentsOfFile: self.globalConfigPath, encoding: .utf8) {
                // Remove the block structurally (by its config-path target) and re-sort,
                // instead of a fragile literal substring match.
                let newGlobal = gitConfigRemovingBlock(configPath: profile.configPath, from: currentGlobal)
                do {
                    try newGlobal.write(toFile: self.globalConfigPath, atomically: true, encoding: .utf8)
                } catch {
                    self.reportError("Couldn't update ~/.gitconfig — check file permissions.")
                }
            }
            // SSH key files are intentionally preserved (documented behavior).
            try? FileManager.default.removeItem(atPath: NSString(string: profile.configPath).expandingTildeInPath)
            DispatchQueue.main.async { self.refreshAll() }
        }
    }

    func copySSHKey(for profile: GitProfile) -> Bool {
        let expandedPath = NSString(string: profile.configPath).expandingTildeInPath
        // core.sshCommand looks like: ssh -i <keypath>
        let sshCommand = Shell.run("git", ["config", "-f", expandedPath, "core.sshCommand"])
        guard let range = sshCommand.range(of: "-i ") else { return false }
        let keyPath = String(sshCommand[range.upperBound...])
            .trimmingCharacters(in: CharacterSet(charactersIn: " \""))
        guard let pubKey = try? String(contentsOfFile: keyPath + ".pub", encoding: .utf8) else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(pubKey, forType: .string)
        return true
    }
    
    /// Rewrites ~/.gitconfig so includeIf blocks are ordered by folder specificity
    /// (deepest last). Safe: only writes when ordering actually changes, writes
    /// atomically, and preserves every block.
    private func normalizeGlobalConfigOrder() {
        guard let content = try? String(contentsOfFile: globalConfigPath, encoding: .utf8) else { return }
        let reordered = reorderGitIncludeBlocks(in: content)
        if reordered != content {
            try? reordered.write(toFile: globalConfigPath, atomically: true, encoding: .utf8)
        }
    }

    private func writeLocalConfig(path: String, name: String, email: String, keyFile: String) {
        let configContent = """
[user]
    name = \(name)
    email = \(email)
[core]
    sshCommand = "ssh -i \(keyFile)"
"""
        do {
            try configContent.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            reportError("Couldn't write the profile config file.")
        }
    }
}

// MARK: - THEME SYSTEM

enum AppTheme: String, CaseIterable, Identifiable {
    case blue, purple, pink, orange, green, teal
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    // `color`, `rgb`, and `onAccent` are defined in Theme.swift (single RGB source in Contrast.swift).
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .blue
    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system
    
    var accentColor: Color {
        selectedTheme.color
    }

    /// Legible foreground (black/white) for text/glyphs drawn on the accent color.
    var accentForeground: Color {
        selectedTheme.onAccent
    }

    func applyAppearance() {
        switch appearanceMode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - UI LAYER

struct ContentView: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @State private var showingAddSheet = false

    var body: some View {
        MainView(manager: manager, themeManager: themeManager, showingAddSheet: $showingAddSheet)
            .frame(minWidth: 600, minHeight: 500)
            .onAppear { themeManager.applyAppearance() }
            .onChange(of: themeManager.appearanceMode) { _, _ in
                themeManager.applyAppearance()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddProfileSheet(manager: manager, themeManager: themeManager)
            }
    }
}

struct MainView: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @Binding var showingAddSheet: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editingProfile: GitProfile?
    @State private var appeared = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HeaderView(
                    themeManager: themeManager,
                    isLoading: manager.isLoading,
                    onRefresh: { manager.refreshAll() },
                    onAdd: { showingAddSheet = true }
                )
                .padding(.horizontal, 32)
                .padding(.top, 20)
                
                // Global Identity
                GlobalIdentityCard(manager: manager, themeManager: themeManager)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                
                // Profiles Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Profiles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        Text("\(manager.profiles.count) profile\(manager.profiles.count == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if manager.profiles.isEmpty && !manager.isLoading {
                        EmptyStateView(themeManager: themeManager) {
                            showingAddSheet = true
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(manager.profiles.enumerated()), id: \.element.id) { index, profile in
                                ProfileCard(profile: profile, manager: manager, themeManager: themeManager) {
                                    editingProfile = profile
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared || reduceMotion ? 0 : 15)
                                .animation(
                                    reduceMotion ? nil :
                                        .spring(response: 0.4, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.05 + 0.15),
                                    value: appeared
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $editingProfile) { profile in
            EditProfileSheet(profile: profile, manager: manager, themeManager: themeManager)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { manager.lastError != nil },
            set: { if !$0 { manager.lastError = nil } }
        )) {
            Button("OK", role: .cancel) { manager.lastError = nil }
        } message: {
            Text(manager.lastError ?? "")
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct HeaderView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.openSettings) private var openSettings
    let isLoading: Bool
    let onRefresh: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Logo
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(themeManager.accentColor)
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.accentForeground)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Git Switch")
                        .font(.system(size: 16, weight: .bold))
                    Text("Profile Manager")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                IconButton(icon: "arrow.clockwise", isLoading: isLoading, action: onRefresh)
                    .help("Refresh")
                
                IconButton(icon: "plus", themeManager: themeManager, isPrimary: true, action: onAdd)
                    .help("Add Profile")

                IconButton(icon: "gearshape", action: { openSettings() })
                    .help("Settings")
            }
        }
    }
}

struct IconButton: View {
    let icon: String
    var themeManager: ThemeManager? = nil
    var isLoading: Bool = false
    var isPrimary: Bool = false
    var label: String? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var rotation: Double = 0

    private var a11yLabel: String {
        if let label { return label }
        switch icon {
        case "arrow.clockwise": return "Refresh"
        case "plus": return "Add profile"
        case "gearshape": return "Settings"
        default: return icon
        }
    }

    var body: some View {
        Button(action: {
            if icon == "arrow.clockwise" && !isLoading && !reduceMotion {
                withAnimation(.linear(duration: 0.6)) {
                    rotation += 360
                }
            }
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isPrimary ? (themeManager?.accentColor ?? .blue) : Color.primary.opacity(isHovering ? 0.12 : 0.06))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPrimary ? (themeManager?.accentForeground ?? .white) : .primary)
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(icon == "arrow.clockwise" ? rotation : 0), anchor: .center)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(a11yLabel)
        .disabled(isLoading && icon == "arrow.clockwise")
        .opacity(isLoading && icon == "arrow.clockwise" ? 0.5 : 1)
        .onHover { hover in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { isHovering = hover }
        }
    }
}

struct GlobalIdentityCard: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editEmail = ""
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor)
                        .frame(width: 52, height: 52)
                    
                    Text(initials)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.accentForeground)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Global Identity")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        VStack(spacing: 8) {
                            CompactTextField(placeholder: "Name", text: $editName, themeManager: themeManager)
                            CompactTextField(placeholder: "Email", text: $editEmail, themeManager: themeManager)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(manager.globalName.isEmpty ? "Not configured" : manager.globalName)
                                .font(.system(size: 15, weight: .semibold))
                            Text(manager.globalEmail.isEmpty ? "—" : manager.globalEmail)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                        if isEditing {
                            manager.saveGlobalConfig(name: editName.trimmingCharacters(in: .whitespacesAndNewlines),
                                                     email: editEmail.trimmingCharacters(in: .whitespacesAndNewlines))
                        } else {
                            editName = manager.globalName
                            editEmail = manager.globalEmail
                        }
                        isEditing.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isEditing ? "Save" : "Edit")
                            .font(.system(size: 12, weight: .medium))
                    }
                        .foregroundColor(isEditing ? themeManager.accentForeground : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isEditing ? themeManager.accentColor : Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(isEditing ? "Save global identity" : "Edit global identity")
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .cardShadow(hovering: isHovering)
        )
        .scaleEffect(isHovering && !reduceMotion ? 1.01 : 1)
        .onHover { hover in
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) { isHovering = hover }
        }
    }
    
    var initials: String {
        let name = manager.globalName.isEmpty ? "?" : manager.globalName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct ProfileCard: View {
    let profile: GitProfile
    let manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    let onEdit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var showDeleteAlert = false
    @State private var copyState: CopyState = .idle

    enum CopyState { case idle, copied }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(themeManager.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.accentColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.system(size: 14, weight: .semibold))
                Text(profile.email)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(profile.folder)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Actions — always visible (never hover-gated) so they're discoverable and
            // reachable by keyboard / VoiceOver.
            HStack(spacing: 6) {
                ActionButton(
                    icon: copyState == .copied ? "checkmark" : "key.fill",
                    color: copyState == .copied ? .green : .secondary,
                    label: copyState == .copied ? "Copied" : "Copy SSH key"
                ) {
                    if manager.copySSHKey(for: profile) {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) {
                            copyState = .copied
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(reduceMotion ? nil : .default) { copyState = .idle }
                        }
                    }
                }
                .help("Copy SSH Key")

                ActionButton(icon: "pencil", color: .secondary, label: "Edit profile", action: onEdit)
                    .help("Edit Profile")

                ActionButton(icon: "trash", color: .red.opacity(0.8), label: "Delete profile") {
                    showDeleteAlert = true
                }
                .help("Delete Profile")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .cardShadow(hovering: isHovering)
        )
        .scaleEffect(isHovering && !reduceMotion ? 1.01 : 1)
        .onHover { hover in
            withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8)) { isHovering = hover }
        }
        .alert("Delete Profile?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                manager.deleteProfile(profile)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the \"\(profile.name)\" profile for \(profile.folder). The generated SSH key is kept.")
        }
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    var label: String = ""
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        // Faint persistent fill so the control reads as tappable at rest.
                        .fill(isHovering ? color.opacity(0.16) : Color.primary.opacity(0.05))
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label.isEmpty ? icon : label)
        .onHover { hover in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { isHovering = hover }
        }
    }
}

struct EmptyStateView: View {
    @ObservedObject var themeManager: ThemeManager
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 26))
                    .foregroundColor(themeManager.accentColor)
            }
            
            VStack(spacing: 4) {
                Text("No profiles yet")
                    .font(.system(size: 14, weight: .semibold))
                Text("Create a profile to auto-switch your Git identity by folder")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Button(action: onAdd) {
                Text("Add Profile")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.accentForeground)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(themeManager.accentColor)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

// MARK: - SHEETS

struct AddProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @State private var name = ""
    @State private var email = ""
    @State private var folder = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) &&
        !folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                }
                
                Text("New Profile")
                    .font(.system(size: 18, weight: .bold))
                Text("Auto-switch Git identity by folder")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "IDENTITY")
                    VStack(spacing: 8) {
                        FormTextField(icon: "person", placeholder: "Profile name (e.g., Work)", text: $name, themeManager: themeManager)
                        FormTextField(icon: "envelope", placeholder: "Email address", text: $email, themeManager: themeManager)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "FOLDER")
                    HStack(spacing: 8) {
                        FormTextField(icon: "folder", placeholder: "Folder this applies to (e.g. ~/Projects/Work)", text: $folder, themeManager: themeManager)
                        Button(action: selectFolder) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(nsColor: .controlColor))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choose folder")
                        .help("Choose folder")
                    }
                }
            }

            if let errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .foregroundColor(.red)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                )
            }

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: create) {
                    HStack(spacing: 6) {
                        if isGenerating {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                        }
                        Text(isGenerating ? "Creating..." : "Create")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(themeManager.accentForeground)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isValid ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid || isGenerating)
            }
        }
        .padding(28)
        .frame(width: 440)
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK {
            folder = panel.url?.path ?? ""
        }
    }
    
    func create() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFolder = folder.trimmingCharacters(in: .whitespacesAndNewlines)

        var isDir: ObjCBool = false
        let expandedFolder = (trimmedFolder as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedFolder, isDirectory: &isDir), isDir.boolValue else {
            errorMessage = "That folder doesn't exist."
            return
        }

        isGenerating = true
        errorMessage = nil
        manager.createProfile(name: trimmedName, email: trimmedEmail, folder: trimmedFolder) { error in
            isGenerating = false
            if let error = error {
                errorMessage = error
            } else {
                dismiss()
            }
        }
    }
}

struct EditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    let profile: GitProfile
    var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @State private var name: String
    @State private var email: String
    
    init(profile: GitProfile, manager: GitManager, themeManager: ThemeManager) {
        self.profile = profile
        self.manager = manager
        self.themeManager = themeManager
        _name = State(initialValue: profile.name)
        _email = State(initialValue: profile.email)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Edit Profile")
                    .font(.system(size: 16, weight: .semibold))
                Text(profile.folder)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            VStack(spacing: 10) {
                FormTextField(icon: "person", placeholder: "Name", text: $name, themeManager: themeManager)
                FormTextField(icon: "envelope", placeholder: "Email", text: $email, themeManager: themeManager)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    manager.updateProfile(profile: profile,
                                          newName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                          newEmail: email.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.accentForeground)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Capsule().fill(themeManager.accentColor))
                .buttonStyle(ScaleButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || !isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        .padding(28)
        .frame(width: 440)
    }
}

struct SettingsView: View {
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 20)

            VStack(spacing: 20) {
                AppearanceSection(themeManager: themeManager)
                AccentColorSection(themeManager: themeManager)
            }
            .padding(20)

            Divider()
                .padding(.horizontal, 20)

            SettingsFooter()
        }
        .frame(width: 360)
    }
}

struct SettingsFooter: View {
    var body: some View {
        HStack {
            Text("Git Switch")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(AppInfo.version)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct AppearanceSection: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(.system(size: 13, weight: .medium))
            
            HStack(spacing: 4) {
                ForEach(AppearanceMode.allCases) { mode in
                    AppearanceModeButton(mode: mode, themeManager: themeManager)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
        }
    }
}

struct AppearanceModeButton: View {
    let mode: AppearanceMode
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isSelected: Bool {
        themeManager.appearanceMode == mode
    }

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                themeManager.appearanceMode = mode
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 12, weight: .medium))
                Text(mode.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? themeManager.accentForeground : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? themeManager.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct AccentColorSection: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Accent Color")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text(themeManager.selectedTheme.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 0) {
                ForEach(AppTheme.allCases) { theme in
                    AccentColorButton(theme: theme, themeManager: themeManager)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }
}

struct AccentColorButton: View {
    let theme: AppTheme
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isSelected: Bool {
        themeManager.selectedTheme == theme
    }

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                themeManager.selectedTheme = theme
            }
        } label: {
            ZStack {
                Circle()
                    .fill(theme.color)
                    .frame(width: 28, height: 28)

                if isSelected {
                    // High-contrast ring drawn OUTSIDE the swatch so the selection reads
                    // clearly in both light and dark mode (the old 30%-white inner ring
                    // vanished on the bright accents).
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.9), lineWidth: 2)
                        .frame(width: 36, height: 36)

                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.onAccent)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? theme.color.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(theme.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - COMPONENTS

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.tertiary)
            .tracking(0.5)
    }
}

struct FormTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @ObservedObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(isFocused ? themeManager.accentColor : .secondary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isFocused ? themeManager.accentColor.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

struct CompactTextField: View {
    let placeholder: String
    @Binding var text: String
    @ObservedObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .focused($isFocused)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isFocused ? themeManager.accentColor.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - BUTTON STYLES

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
