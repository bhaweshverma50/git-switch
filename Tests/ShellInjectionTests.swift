import Foundation

// Standalone security test for Shell.run. Compiled with the real Shell.swift via:
//   swiftc "Git Switch/Shell.swift" Tests/ShellInjectionTests.swift -o /tmp/shelltests && /tmp/shelltests
// Proves that arguments are passed directly to execve (no shell), so user input
// containing shell metacharacters can never be interpreted as a command.

@main
struct ShellInjectionTests {
    static func main() {
        var failures = 0
        func check(_ cond: Bool, _ msg: String) {
            if cond { print("PASS: \(msg)") }
            else { print("FAIL: \(msg)"); failures += 1 }
        }

        let canary = "/tmp/gitswitch_injection_canary_\(getpid())"
        try? FileManager.default.removeItem(atPath: canary)

        // A classic command-substitution payload. If Shell.run goes through a shell,
        // `$(touch …)` executes (creating the canary) and `; echo pwned` runs.
        let payload = "$(touch \(canary)); echo pwned"

        // printf %s <payload> must echo the payload VERBATIM if no shell is involved.
        let out = Shell.run("printf", ["%s", payload])

        check(out == payload, "argument passed verbatim (no shell interpretation)")
        check(!FileManager.default.fileExists(atPath: canary), "command substitution did NOT execute (no canary file)")

        // A double quote in an argument must survive literally (the original bug broke
        // `git config user.name "O\"Brien"`-style values).
        let quoted = Shell.run("printf", ["%s", #"O"Brien $HOME"#])
        check(quoted == #"O"Brien $HOME"#, "quotes and $ in an argument are passed literally")

        try? FileManager.default.removeItem(atPath: canary)

        if failures == 0 { print("\nALL TESTS PASSED") }
        else { print("\n\(failures) TEST(S) FAILED"); exit(1) }
    }
}
