import Foundation

/// Number of path components in a `gitdir:` folder pattern, e.g. "/a/b/" -> 2.
/// Used as the specificity metric: a deeper folder is more specific.
func gitdirDepth(_ folder: String) -> Int {
    folder.split(separator: "/").count
}

/// Reorders every `[includeIf "gitdir:..."]` block in a gitconfig so the most
/// specific (deepest) folder appears LAST.
///
/// Git applies *all* matching `includeIf` blocks in the order they appear in the
/// file, and for any conflicting key (e.g. `user.email`) the **last** value wins.
/// It has no notion of path specificity. So for nested folders — say `/downloads`
/// and `/downloads/test` — whichever block is written last wins inside the child
/// directory. The app appends new blocks in creation order, which is why a parent
/// profile created after a child silently overrides it.
///
/// Sorting blocks shallow -> deep guarantees the most specific matching folder is
/// applied last and therefore wins. Because an ancestor path is always a strict
/// prefix of (and thus shallower than) its descendants, this ordering always
/// places a parent before its children.
///
/// Non-`includeIf` content is preserved and the transformation is idempotent.
func reorderGitIncludeBlocks(in content: String) -> String {
    // Matches a two-line includeIf/gitdir block. `(?m)` makes ^/$ line anchors;
    // `.` does not span newlines, so the path stays on its own line. `$` also
    // matches end-of-string, so a final block without a trailing newline matches.
    let pattern = #"(?m)^[ \t]*\[includeIf "gitdir:([^"]*)"\][ \t]*\r?\n[ \t]*path[ \t]*=[ \t]*(.+?)[ \t]*$"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return content }

    let ns = content as NSString
    let matches = regex.matches(in: content, range: NSRange(location: 0, length: ns.length))
    // With 0 or 1 managed block there is nothing that can overlap, so leave the
    // file untouched (avoids gratuitous rewrites / formatting churn).
    guard matches.count > 1 else { return content }

    // Capture each block's folder + path in file order.
    var blocks: [(folder: String, path: String)] = []
    for m in matches {
        let folder = ns.substring(with: m.range(at: 1))
        let path = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces)
        blocks.append((folder, path))
    }

    // Strip the matched blocks out of the content (reverse order keeps ranges valid).
    let mutable = NSMutableString(string: content)
    for m in matches.reversed() {
        mutable.replaceCharacters(in: m.range(at: 0), with: "")
    }

    // Shallowest first, deepest last. Ties broken deterministically so output is stable.
    let sorted = blocks.sorted { a, b in
        let da = gitdirDepth(a.folder), db = gitdirDepth(b.folder)
        if da != db { return da < db }
        if a.folder.count != b.folder.count { return a.folder.count < b.folder.count }
        return a.folder < b.folder
    }

    // Preserve the remaining (non-includeIf) content, collapse the blank lines the
    // removal left behind, then re-emit the blocks in specificity order.
    var head = (mutable as String).replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
    head = head.trimmingCharacters(in: .whitespacesAndNewlines)

    var result = head
    for b in sorted {
        result += "\n\n[includeIf \"gitdir:\(b.folder)\"]\n    path = \(b.path)"
    }
    return result + "\n"
}

// Matches an includeIf/gitdir block. `(?i)` accepts `gitdir` and the case-insensitive
// `gitdir/i` variant and tolerates case; `(?m)` makes `$` match end-of-line OR end of
// string (so a final block without a trailing newline still parses); indentation may be
// spaces or tabs.
private let includeBlockPattern =
    #"(?im)^[ \t]*\[includeIf "gitdir(?:/i)?:([^"]*)"\][ \t]*\r?\n[ \t]*path[ \t]*=[ \t]*(.+?)[ \t]*$"#

/// Parses every includeIf/gitdir block into (folder, configPath, fullBlockText),
/// in file order. Robust to the `gitdir/i` variant, tab indentation, and a missing
/// trailing newline on the last block.
func parseIncludeBlocks(in content: String) -> [(folder: String, configPath: String, block: String)] {
    guard let regex = try? NSRegularExpression(pattern: includeBlockPattern) else { return [] }
    let ns = content as NSString
    var result: [(folder: String, configPath: String, block: String)] = []
    for m in regex.matches(in: content, range: NSRange(location: 0, length: ns.length)) {
        let folder = ns.substring(with: m.range(at: 1))
        let path = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces)
        let block = ns.substring(with: m.range(at: 0))
        result.append((folder, path, block))
    }
    return result
}

/// Removes every includeIf gitdir block whose `path` target equals `configPath`,
/// then re-sorts the remainder. Structural (parse-based), so unlike literal string
/// replacement it is robust to whitespace/formatting and never leaves orphaned lines.
func gitConfigRemovingBlock(configPath: String, from content: String) -> String {
    guard let regex = try? NSRegularExpression(pattern: includeBlockPattern) else { return content }
    let ns = content as NSString
    let matches = regex.matches(in: content, range: NSRange(location: 0, length: ns.length))
    let mutable = NSMutableString(string: content)
    for m in matches.reversed() {
        let path = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces)
        if path == configPath {
            mutable.replaceCharacters(in: m.range(at: 0), with: "")
        }
    }
    return reorderGitIncludeBlocks(in: mutable as String)
}
