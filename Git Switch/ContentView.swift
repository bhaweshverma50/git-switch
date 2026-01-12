import SwiftUI
import AppKit
import Combine

// MARK: - MENU BAR VIEW

struct MenuBarView: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
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
                        .foregroundColor(.white)
                }
                
                Text("Git Switch")
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.linear(duration: 0.6)) {
                        refreshRotation += 360
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
                .frame(maxHeight: 200)
            }
            
            Divider()
            
            // Footer Actions
            HStack(spacing: 8) {
                Button(action: openMainWindow) {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 10))
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
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue != "menu-bar" }) {
            window.makeKeyAndOrderFront(nil)
        }
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
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Global Identity")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                Text(manager.globalName.isEmpty ? "Not Set" : manager.globalName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(manager.globalEmail.isEmpty ? "—" : manager.globalEmail)
                    .font(.system(size: 10))
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
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Button(action: copyKey) {
                Image(systemName: isCopied ? "checkmark" : "key.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isCopied ? .green : .secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(ScaleButtonStyle())
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

class Shell {
    @discardableResult
    static func run(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        do { try task.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

struct GitProfile: Identifiable, Equatable {
    let id = UUID()
    var folder: String
    var name: String
    var email: String
    var configPath: String
    var includeBlock: String
}

class GitManager: ObservableObject {
    @Published var profiles: [GitProfile] = []
    @Published var globalName: String = ""
    @Published var globalEmail: String = ""
    @Published var isLoading = false
    
    private let globalConfigPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gitconfig").path
    private let sshDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh").path

    init() { refreshAll() }
    
    func refreshAll() {
        withAnimation(.easeOut(duration: 0.2)) { isLoading = true }
        DispatchQueue.global(qos: .userInitiated).async {
            let gName = Shell.run("git config --global user.name")
            let gEmail = Shell.run("git config --global user.email")
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
        Shell.run("git config --global user.name \"\(name)\"")
        Shell.run("git config --global user.email \"\(email)\"")
        refreshAll()
    }

    private func fetchProfiles() -> [GitProfile] {
        guard let content = try? String(contentsOfFile: globalConfigPath, encoding: .utf8) else { return [] }
        var found: [GitProfile] = []
        let pattern = #"(?ms)(\[includeIf "gitdir:(.*?)"\]\s+path\s+=\s+(.*?)\n)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsString = content as NSString
        let results = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for result in results {
            let fullBlock = nsString.substring(with: result.range(at: 1))
            let folder = nsString.substring(with: result.range(at: 2))
            let configPath = nsString.substring(with: result.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
            let details = readProfileDetails(path: configPath)
            found.append(GitProfile(folder: folder, name: details.name, email: details.email, configPath: configPath, includeBlock: fullBlock))
        }
        return found
    }
    
    private func readProfileDetails(path: String) -> (name: String, email: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        guard let content = try? String(contentsOfFile: expandedPath, encoding: .utf8) else { return ("Unknown", "Unknown") }
        var name = "Unknown", email = "Unknown"
        content.enumerateLines { line, _ in
            if let range = line.range(of: "name =") { name = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces) }
            if let range = line.range(of: "email =") { email = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces) }
        }
        return (name, email)
    }

    func createProfile(name: String, email: String, folder: String, completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            let safeName = name.lowercased().replacingOccurrences(of: " ", with: "_")
            let keyFile = "\(self.sshDir)/id_ed25519_\(safeName)"
            let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gitconfig_\(safeName)").path

            if !FileManager.default.fileExists(atPath: self.sshDir) { try? FileManager.default.createDirectory(atPath: self.sshDir, withIntermediateDirectories: true) }
            if !FileManager.default.fileExists(atPath: keyFile) {
                Shell.run("ssh-keygen -t ed25519 -C \"\(email)\" -f \"\(keyFile)\" -N \"\"")
            }
            Shell.run("ssh-add --apple-use-keychain \"\(keyFile)\"")
            
            self.writeLocalConfig(path: configPath, name: name, email: email, keyFile: keyFile)
            
            let includeDirective = "\n[includeIf \"gitdir:\(folder)/\"]\n    path = \(configPath)\n"
            if let currentGlobal = try? String(contentsOfFile: self.globalConfigPath, encoding: .utf8) {
                if !currentGlobal.contains(configPath) {
                    let newGlobal = currentGlobal + includeDirective
                    try? newGlobal.write(toFile: self.globalConfigPath, atomically: true, encoding: .utf8)
                }
            }
            DispatchQueue.main.async { self.refreshAll(); completion() }
        }
    }
    
    func updateProfile(profile: GitProfile, newName: String, newEmail: String) {
        let expandedPath = NSString(string: profile.configPath).expandingTildeInPath
        guard let content = try? String(contentsOfFile: expandedPath, encoding: .utf8) else { return }
        var keyPath = ""
        if let range = content.range(of: "sshCommand = \"ssh -i ") {
             keyPath = String(content[range.upperBound...].split(separator: "\"").first ?? "")
        }
        writeLocalConfig(path: expandedPath, name: newName, email: newEmail, keyFile: keyPath)
        refreshAll()
    }
    
    func deleteProfile(_ profile: GitProfile) {
        if let currentGlobal = try? String(contentsOfFile: globalConfigPath, encoding: .utf8) {
            let newGlobal = currentGlobal.replacingOccurrences(of: profile.includeBlock, with: "")
            try? newGlobal.write(toFile: globalConfigPath, atomically: true, encoding: .utf8)
        }
        try? FileManager.default.removeItem(atPath: NSString(string: profile.configPath).expandingTildeInPath)
        refreshAll()
    }
    
    func copySSHKey(for profile: GitProfile) -> Bool {
        let expandedPath = NSString(string: profile.configPath).expandingTildeInPath
        guard let content = try? String(contentsOfFile: expandedPath, encoding: .utf8),
              let range = content.range(of: "ssh -i ") else { return false }
        let keyPath = content[range.upperBound...].components(separatedBy: "\"").first ?? ""
        let pubKeyPath = keyPath + ".pub"
        if let pubKey = try? String(contentsOfFile: pubKeyPath, encoding: .utf8) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(pubKey, forType: .string)
            return true
        }
        return false
    }
    
    private func writeLocalConfig(path: String, name: String, email: String, keyFile: String) {
        let configContent = """
[user]
    name = \(name)
    email = \(email)
[core]
    sshCommand = "ssh -i \(keyFile)"
"""
        try? configContent.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

// MARK: - THEME SYSTEM

enum AppTheme: String, CaseIterable, Identifiable {
    case blue, purple, pink, orange, green, teal
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .blue: return Color(nsColor: NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0))
        case .purple: return Color(nsColor: NSColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0))
        case .pink: return Color(nsColor: NSColor(red: 0.94, green: 0.28, blue: 0.5, alpha: 1.0))
        case .orange: return Color(nsColor: NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0))
        case .green: return Color(nsColor: NSColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0))
        case .teal: return Color(nsColor: NSColor(red: 0.0, green: 0.73, blue: 0.82, alpha: 1.0))
        }
    }
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
    @State private var showingSettings = false
    
    var body: some View {
        MainView(manager: manager, themeManager: themeManager, showingAddSheet: $showingAddSheet, showingSettings: $showingSettings)
            .frame(minWidth: 600, minHeight: 500)
            .onAppear { themeManager.applyAppearance() }
            .onChange(of: themeManager.appearanceMode) { _, _ in
                themeManager.applyAppearance()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddProfileSheet(manager: manager, themeManager: themeManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet(themeManager: themeManager)
            }
    }
}

struct MainView: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
    @Binding var showingAddSheet: Bool
    @Binding var showingSettings: Bool
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
                    onAdd: { showingAddSheet = true },
                    onSettings: { showingSettings = true }
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
                        Text("Context Profiles")
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
                                .offset(y: appeared ? 0 : 15)
                                .animation(
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct HeaderView: View {
    @ObservedObject var themeManager: ThemeManager
    let isLoading: Bool
    let onRefresh: () -> Void
    let onAdd: () -> Void
    let onSettings: () -> Void
    
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
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Git Switch")
                        .font(.system(size: 16, weight: .bold))
                    Text("Identity Manager")
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
                    .help("Add Context")
                
                IconButton(icon: "gearshape", action: onSettings)
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
    let action: () -> Void
    
    @State private var isHovering = false
    @State private var rotation: Double = 0
    
    var body: some View {
        Button(action: {
            if icon == "arrow.clockwise" && !isLoading {
                withAnimation(.linear(duration: 0.6)) {
                    rotation += 360
                }
            }
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isPrimary ? (themeManager?.accentColor ?? .blue) : (isHovering ? Color.primary.opacity(0.06) : Color.clear))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPrimary ? .white : .primary)
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(icon == "arrow.clockwise" ? rotation : 0), anchor: .center)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading && icon == "arrow.clockwise")
        .opacity(isLoading && icon == "arrow.clockwise" ? 0.5 : 1)
        .onHover { hover in
            withAnimation(.easeOut(duration: 0.15)) { isHovering = hover }
        }
    }
}

struct GlobalIdentityCard: View {
    @ObservedObject var manager: GitManager
    @ObservedObject var themeManager: ThemeManager
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
                        .foregroundColor(.white)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isEditing {
                            manager.saveGlobalConfig(name: editName, email: editEmail)
                        } else {
                            editName = manager.globalName
                            editEmail = manager.globalEmail
                        }
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? "Save" : "Edit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isEditing ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isEditing ? themeManager.accentColor : Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.1 : 0.05), radius: isHovering ? 12 : 8, y: isHovering ? 4 : 2)
        )
        .scaleEffect(isHovering ? 1.005 : 1)
        .onHover { hover in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isHovering = hover }
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
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 6) {
                ActionButton(
                    icon: copyState == .copied ? "checkmark" : "key.fill",
                    color: copyState == .copied ? .green : .secondary
                ) {
                    if manager.copySSHKey(for: profile) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            copyState = .copied
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copyState = .idle }
                        }
                    }
                }
                .help("Copy SSH Key")
                
                ActionButton(icon: "pencil", color: .secondary, action: onEdit)
                    .help("Edit Profile")
                
                ActionButton(icon: "trash", color: .red.opacity(0.8)) {
                    showDeleteAlert = true
                }
                .help("Delete Profile")
            }
            .opacity(isHovering ? 1 : 0.4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.08 : 0.03), radius: isHovering ? 8 : 4, y: isHovering ? 2 : 1)
        )
        .scaleEffect(isHovering ? 1.008 : 1)
        .onHover { hover in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { isHovering = hover }
        }
        .alert("Delete Context?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    manager.deleteProfile(profile)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the Git identity for '\(profile.folder)'.")
        }
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isHovering ? color.opacity(0.12) : Color.clear)
                )
                .scaleEffect(isPressed ? 0.9 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hover }
        }
        .pressAction {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isPressed = true }
        } onRelease: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isPressed = false }
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
                Text("No contexts yet")
                    .font(.system(size: 14, weight: .semibold))
                Text("Create a context to auto-switch identities")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Button(action: onAdd) {
                Text("Add Context")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
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
    
    var isValid: Bool { !name.isEmpty && !email.isEmpty && !folder.isEmpty }
    
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
                
                Text("New Context")
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
                        FormTextField(icon: "folder", placeholder: "Path to projects folder", text: $folder, themeManager: themeManager)
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
                    }
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isValid ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isValid || isGenerating)
            }
        }
        .padding(28)
        .frame(width: 420)
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
        isGenerating = true
        manager.createProfile(name: name, email: email, folder: folder) {
            isGenerating = false
            dismiss()
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
                Text("Edit Identity")
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
                
                Spacer()
                
                Button("Save") {
                    manager.updateProfile(profile: profile, newName: name, newEmail: email)
                    dismiss()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Capsule().fill(themeManager.accentColor))
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(28)
        .frame(width: 380)
    }
}

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsHeader(onDismiss: { dismiss() })
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 20) {
                AppearanceSection(themeManager: themeManager)
                AccentColorSection(themeManager: themeManager)
            }
            .padding(20)
            
            Spacer()
            
            Divider()
                .padding(.horizontal, 20)
            
            SettingsFooter()
        }
        .frame(width: 320, height: 300)
    }
}

struct SettingsHeader: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
    }
}

struct SettingsFooter: View {
    var body: some View {
        HStack {
            Text("Git Switch")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text("v1.0")
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
    
    private var isSelected: Bool {
        themeManager.appearanceMode == mode
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                themeManager.appearanceMode = mode
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 12, weight: .medium))
                Text(mode.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? themeManager.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
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
    
    private var isSelected: Bool {
        themeManager.selectedTheme == theme
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                themeManager.selectedTheme = theme
            }
        } label: {
            ZStack {
                Circle()
                    .fill(theme.color)
                    .frame(width: 28, height: 28)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
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
    }
}

// MARK: - COMPONENTS

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
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

// MARK: - PRESS ACTION MODIFIER

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}
