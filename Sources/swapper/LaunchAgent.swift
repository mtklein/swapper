import Foundation

/// A per-user launchd agent that keeps `swapper watch` running while logged in.
enum LaunchAgent {
    static let label = "com.mtklein.swapper"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var logURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/swapper.log")
    }

    private static var domain: String { "gui/\(getuid())" }
    private static var service: String { "\(domain)/\(label)" }

    static var isLoaded: Bool {
        (try? Shell.run("/bin/launchctl", "print", service)) != nil
    }

    static func install(executable: URL) throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executable.path, "watch"],
            "RunAtLoad": true,
            "KeepAlive": true,
            "StandardOutPath": logURL.path,
            "StandardErrorPath": logURL.path,
            // launchd gives agents a minimal PATH; make Homebrew and ~/.local/bin visible to hook scripts.
            "EnvironmentVariables": [
                "PATH": "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            ],
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        _ = try? Shell.run("/bin/launchctl", "bootout", service)
        try data.write(to: plistURL)

        // bootout is asynchronous; bootstrap can briefly fail with "already loaded".
        var lastError: Error?
        for _ in 0..<20 {
            do {
                try Shell.run("/bin/launchctl", "bootstrap", domain, plistURL.path)
                return
            } catch {
                lastError = error
                usleep(250_000)
            }
        }
        throw lastError ?? SwapperError("launchctl bootstrap failed")
    }

    static func uninstall() throws {
        _ = try? Shell.run("/bin/launchctl", "bootout", service)
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }
}
