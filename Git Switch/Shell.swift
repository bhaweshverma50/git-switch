import Foundation

enum Shell {
    /// Runs an executable with its arguments passed directly to `execve` (via
    /// `/usr/bin/env` for PATH resolution) — never through a shell. Because nothing
    /// is concatenated into a command string, user input such as a name containing
    /// `"`, `$()`, backticks, or `;` is treated as literal argument data and can
    /// never be interpreted as shell syntax. Returns trimmed combined stdout/stderr.
    @discardableResult
    static func run(_ executable: String, _ arguments: [String]) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = [executable] + arguments
        do { try task.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
