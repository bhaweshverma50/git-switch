import Foundation

// Compile with the real sources:
//   swiftc "Git Switch/GitConfigOrdering.swift" "Git Switch/ProfileSetup.swift" Tests/ParsingAndValidationTests.swift -o /tmp/pvtests && /tmp/pvtests

@main
struct ParsingAndValidationTests {
    static func main() {
        var failures = 0
        func check(_ cond: Bool, _ msg: String) {
            if cond { print("PASS: \(msg)") } else { print("FAIL: \(msg)"); failures += 1 }
        }

        // --- parseIncludeBlocks: robust to no-trailing-newline, gitdir/i, tabs ---
        let cfg = "[user]\n\temail = g\n[includeIf \"gitdir:/a/b/\"]\n    path = /p1\n[includeIf \"gitdir/i:/c/\"]\n\tpath = /p2"
        let blocks = parseIncludeBlocks(in: cfg)
        check(blocks.count == 2, "parses both blocks (incl. last with no trailing newline)")
        if blocks.count == 2 {
            check(blocks[0].folder == "/a/b/" && blocks[0].configPath == "/p1", "first block folder+path")
            check(blocks[1].folder == "/c/" && blocks[1].configPath == "/p2", "gitdir/i variant + tab indent parsed")
        }
        check(parseIncludeBlocks(in: "[user]\n\tname = x").isEmpty, "no blocks -> empty")

        // --- gitConfigRemovingBlock: structural removal by config path ---
        let cfg2 = "[user]\n\temail = g\n[includeIf \"gitdir:/a/b/\"]\n    path = /p1\n[includeIf \"gitdir:/c/\"]\n    path = /p2\n"
        let removed = gitConfigRemovingBlock(configPath: "/p1", from: cfg2)
        check(!removed.contains("/p1"), "target block removed")
        check(removed.contains("/p2"), "other block kept")
        check(removed.contains("email = g"), "global section kept")
        check(!removed.contains("\n\n\n"), "no orphaned blank-line runs")

        // --- isValidEmail: basic shape check ---
        check(isValidEmail("a@b.co"), "a@b.co valid")
        check(isValidEmail("first.last+tag@sub.example.com"), "complex valid")
        check(!isValidEmail("a@b"), "missing TLD invalid")
        check(!isValidEmail("nope"), "missing @ invalid")
        check(!isValidEmail(""), "empty invalid")
        check(!isValidEmail(" a@b.co "), "surrounding whitespace invalid")

        if failures == 0 { print("\nALL TESTS PASSED") }
        else { print("\n\(failures) TEST(S) FAILED"); exit(1) }
    }
}
