import Foundation

// Standalone tests for the profile-setup helpers. Compiled with the real source:
//   swiftc "Git Switch/ProfileSetup.swift" Tests/ProfileSetupTests.swift -o /tmp/setuptests && /tmp/setuptests

@main
struct ProfileSetupTests {
    static func main() {
        var failures = 0
        func check(_ cond: Bool, _ msg: String) {
            if cond { print("PASS: \(msg)") }
            else { print("FAIL: \(msg)"); failures += 1 }
        }

        // --- sanitizeProfileSlug: filesystem-safe, collision-prone-by-design slug ---
        check(sanitizeProfileSlug("Work") == "work", "Work -> work")
        check(sanitizeProfileSlug("work") == "work", "work -> work (same slug as Work; uniqueness handled separately)")
        check(sanitizeProfileSlug("My Work!") == "my_work", "spaces & punctuation -> single underscore, trimmed")
        check(sanitizeProfileSlug("../../etc/passwd") == "etc_passwd", "path traversal characters neutralized")
        check(!sanitizeProfileSlug("a/b").contains("/"), "no slash can survive into a filename")
        check(sanitizeProfileSlug("   ") == "profile", "blank/whitespace -> 'profile' fallback")
        check(sanitizeProfileSlug("🚀") == "profile", "non-ascii-only -> 'profile' fallback")

        // --- uniqueSlug: disambiguates against a taken-predicate ---
        check(uniqueSlug("work", isTaken: { _ in false }) == "work", "free base used as-is")
        check(uniqueSlug("work", isTaken: { $0 == "work" }) == "work_2", "taken base -> _2")
        check(uniqueSlug("work", isTaken: { ["work", "work_2"].contains($0) }) == "work_3", "skips taken suffixes")

        // --- normalizeFolderPath: realpath (symlink) + trailing-slash stripping ---
        // /tmp is a symlink to /private/tmp on macOS — Git matches the resolved path.
        check(normalizeFolderPath("/tmp/").hasSuffix("/tmp"), "trailing slash stripped & symlink resolved")
        check(!normalizeFolderPath("/tmp/").hasSuffix("//"), "never produces a double slash")
        check(normalizeFolderPath("/tmp") == normalizeFolderPath("/tmp/"), "trailing slash is insignificant")
        check(normalizeFolderPath("/tmp//") == normalizeFolderPath("/tmp"), "multiple trailing slashes collapsed")

        // --- existingGitdirFolders: detect duplicate folders (slash-insensitive) ---
        let cfg = """
        [user]
        \tname = x
        [includeIf "gitdir:/a/b/"]
            path = /p1
        [includeIf "gitdir:/c/"]
            path = /p2
        """
        let folders = existingGitdirFolders(in: cfg)
        check(folders.contains("/a/b") && folders.contains("/c"), "extracts folders (trailing slash stripped)")
        check(folders.count == 2, "exactly the two includeIf folders")
        check(existingGitdirFolders(in: "[user]\n\tname = x").isEmpty, "empty when there are no includeIf blocks")

        if failures == 0 { print("\nALL TESTS PASSED") }
        else { print("\n\(failures) TEST(S) FAILED"); exit(1) }
    }
}
