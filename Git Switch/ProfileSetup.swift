import Foundation

/// Turns a human profile name into a filesystem-safe slug used for the per-profile
/// config (`~/.gitconfig_<slug>`) and SSH key (`id_ed25519_<slug>`) filenames.
///
/// Lowercased; any character outside `[a-z0-9_-]` becomes `_`; runs of `_` are
/// collapsed; leading/trailing `_ - .` are trimmed. This neutralizes path traversal
/// (`..`, `/`) and other unsafe characters. Falls back to `"profile"` if nothing
/// usable remains. Names that differ only by case/punctuation intentionally collapse
/// to the same slug — `uniqueSlug` then disambiguates so they never clobber.
func sanitizeProfileSlug(_ name: String) -> String {
    var out = ""
    for ch in name.lowercased() {
        if ch.isASCII && (ch.isLetter || ch.isNumber) { out.append(ch) }
        else if ch == "-" || ch == "_" { out.append(ch) }
        else { out.append("_") }
    }
    while out.contains("__") { out = out.replacingOccurrences(of: "__", with: "_") }
    out = out.trimmingCharacters(in: CharacterSet(charactersIn: "_-."))
    return out.isEmpty ? "profile" : out
}

/// Returns `base`, or `base_2`, `base_3`, … — the first variant for which
/// `isTaken` is false. Lets the caller guarantee unique config/key filenames so
/// two profiles can never overwrite each other's files.
func uniqueSlug(_ base: String, isTaken: (String) -> Bool) -> String {
    if !isTaken(base) { return base }
    var n = 2
    while isTaken("\(base)_\(n)") { n += 1 }
    return "\(base)_\(n)"
}

/// Canonicalizes a folder path for use in a `gitdir:` pattern: expands `~`, resolves
/// symlinks and `..` via `realpath` (matching Git, which tests the resolved `.git`
/// path — e.g. `/tmp` -> `/private/tmp`), and strips trailing slashes. Falls back to
/// `standardizingPath` when the path does not exist (so `realpath` can't resolve it).
func normalizeFolderPath(_ folder: String) -> String {
    let expanded = (folder as NSString).expandingTildeInPath
    var result: String
    if let resolved = expanded.withCString({ realpath($0, nil) }) {
        result = String(cString: resolved)
        free(resolved)
    } else {
        result = (expanded as NSString).standardizingPath
    }
    while result.count > 1 && result.hasSuffix("/") { result.removeLast() }
    return result
}

/// The set of `gitdir:` folders already present in a gitconfig, with trailing
/// slashes stripped for comparison. Used to detect (and reject) a second profile
/// for a folder that already has one.
func existingGitdirFolders(in content: String) -> Set<String> {
    let pattern = #"(?m)\[includeIf "gitdir:([^"]*)"\]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    let ns = content as NSString
    var folders = Set<String>()
    for m in regex.matches(in: content, range: NSRange(location: 0, length: ns.length)) {
        var folder = ns.substring(with: m.range(at: 1))
        while folder.count > 1 && folder.hasSuffix("/") { folder.removeLast() }
        folders.insert(folder)
    }
    return folders
}

/// Basic structural email check: non-empty local part, `@`, domain, a dot, and a TLD,
/// with no surrounding or internal whitespace. Deliberately permissive but rejects the
/// obviously-wrong inputs the form should not accept.
func isValidEmail(_ email: String) -> Bool {
    email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: [.regularExpression]) != nil
}
