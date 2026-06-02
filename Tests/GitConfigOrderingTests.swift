import Foundation

// Standalone test harness for the gitconfig include-ordering logic.
// There is no XCTest target in this project, so this is compiled together with
// the real production source via swiftc and run as an executable:
//
//   swiftc "Git Switch/GitConfigOrdering.swift" Tests/GitConfigOrderingTests.swift -o /tmp/reordertests && /tmp/reordertests
//
// It exercises the REAL reorderGitIncludeBlocks(in:) — not a copy.

@main
struct ReorderTests {
    static func main() {
        var failures = 0
        func check(_ cond: Bool, _ msg: String) {
            if cond { print("PASS: \(msg)") }
            else { print("FAIL: \(msg)"); failures += 1 }
        }
        func loc(_ s: String, _ needle: String) -> Int {
            (s as NSString).range(of: needle).location
        }

        // Behavior 1: the deepest (most specific) folder must be ordered LAST so that,
        // under Git's last-match-wins rule for overlapping includeIf blocks, the child
        // folder's identity overrides the parent's.
        let childFirst = """
        [user]
        \temail = global@example.com
        [includeIf "gitdir:/Users/me/downloads/test/"]
            path = /Users/me/.gitconfig_child
        [includeIf "gitdir:/Users/me/downloads/"]
            path = /Users/me/.gitconfig_parent
        """
        let out1 = reorderGitIncludeBlocks(in: childFirst)
        let iParent = loc(out1, "gitdir:/Users/me/downloads/\"")
        let iChild = loc(out1, "gitdir:/Users/me/downloads/test/\"")
        check(iParent != NSNotFound && iChild != NSNotFound, "both blocks present after reorder")
        check(iParent < iChild, "deeper child folder ordered AFTER parent (child wins)")

        // Behavior 2: idempotent — reordering an already-ordered config changes nothing.
        check(reorderGitIncludeBlocks(in: out1) == out1, "reorder is idempotent")

        // Behavior 3: non-includeIf content (the global [user] section) is preserved.
        check(out1.contains("email = global@example.com"), "preserves global [user] section")

        // Behavior 4: no block is dropped — both profile config paths survive.
        check(out1.contains("/Users/me/.gitconfig_child") && out1.contains("/Users/me/.gitconfig_parent"),
              "both profile paths preserved")

        // Behavior 5: a config with a single includeIf block is left intact.
        let single = """
        [user]
        \temail = g
        [includeIf "gitdir:/a/b/"]
            path = /p
        """
        let outS = reorderGitIncludeBlocks(in: single)
        check(outS.contains("gitdir:/a/b/") && outS.contains("path = /p"), "single block preserved")

        // Behavior 6: three nesting levels are ordered shallow -> deep regardless of input order.
        let three = """
        [includeIf "gitdir:/a/b/c/"]
            path = /c
        [includeIf "gitdir:/a/"]
            path = /a
        [includeIf "gitdir:/a/b/"]
            path = /b
        """
        let out3 = reorderGitIncludeBlocks(in: three)
        let ia = loc(out3, "gitdir:/a/\"")
        let ib = loc(out3, "gitdir:/a/b/\"")
        let ic = loc(out3, "gitdir:/a/b/c/\"")
        check(ia < ib && ib < ic, "three levels ordered shallow -> deep")

        if failures == 0 { print("\nALL TESTS PASSED") }
        else { print("\n\(failures) TEST(S) FAILED"); exit(1) }
    }
}
