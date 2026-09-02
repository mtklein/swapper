import Foundation

/// The two user-owned hook scripts: one per mode.
enum Scripts {
    static var directory: URL {
        let env = ProcessInfo.processInfo.environment
        let base = env["XDG_CONFIG_HOME"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config")
        return base.appendingPathComponent("swapper")
    }

    static func url(for mode: Mode) -> URL {
        directory.appendingPathComponent("\(mode.rawValue).sh")
    }

    /// Runs the script for `mode`, inheriting stdout/stderr so output lands in the log.
    @MainActor
    static func run(_ mode: Mode, displays: [Display]) throws {
        let script = url(for: mode)
        guard FileManager.default.fileExists(atPath: script.path) else {
            throw SwapperError("no script at \(script.path); run `swapper init` to create examples")
        }

        let process = Process()
        if FileManager.default.isExecutableFile(atPath: script.path) {
            process.executableURL = script
        } else {
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = [script.path]
        }

        var env = ProcessInfo.processInfo.environment
        env["SWAPPER_MODE"] = mode.rawValue
        env["SWAPPER_DISPLAYS"] = displays.map(\.description).joined(separator: "; ")
        // Make sure `swapper` itself is reachable from the scripts, wherever it was launched from.
        if let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() {
            let bin = executable.deletingLastPathComponent().path
            env["PATH"] = [bin, env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"].joined(separator: ":")
        }
        process.environment = env

        Log.line("running \(script.path)")
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw SwapperError("\(script.lastPathComponent) exited \(process.terminationStatus)")
        }
    }

    /// Writes the example scripts, skipping any that already exist.
    static func writeExamples() throws -> [URL] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var written: [URL] = []
        for (mode, body) in [(Mode.docked, dockedExample), (.mobile, mobileExample)] {
            let url = url(for: mode)
            guard !FileManager.default.fileExists(atPath: url.path) else { continue }
            try body.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            written.append(url)
        }
        return written
    }

    static let dockedExample = """
    #!/bin/sh
    # swapper runs this when an external display is connected.
    #   $SWAPPER_MODE      "docked"
    #   $SWAPPER_DISPLAYS  e.g. "Built-in Retina Display 3024x1964 (built-in); Studio Display 5120x2880"
    set -eu
    PATH="$HOME/.local/bin:$PATH"   # where `make install` puts swapper

    # Dock: always visible. Applied live; no Dock restart, no screen flash.
    swapper dock-autohide off

    # MTG Arena: 3840x2160 window. Read by the game at launch, so it takes effect
    # next time MTGA starts. (Unity "Fullscreen mode": 1 = fullscreen window, 3 = windowed.)
    defaults write com.wizards.mtga "Screenmanager Fullscreen mode" -int 3
    defaults write com.wizards.mtga "Screenmanager Resolution Use Native" -int 0
    defaults write com.wizards.mtga "Screenmanager Resolution Width" -int 3840
    defaults write com.wizards.mtga "Screenmanager Resolution Height" -int 2160

    """

    static let mobileExample = """
    #!/bin/sh
    # swapper runs this when only the built-in display is present.
    #   $SWAPPER_MODE      "mobile"
    #   $SWAPPER_DISPLAYS  e.g. "Built-in Retina Display 3024x1964 (built-in)"
    set -eu
    PATH="$HOME/.local/bin:$PATH"   # where `make install` puts swapper

    # Dock: auto-hide. Applied live; no Dock restart, no screen flash.
    swapper dock-autohide on

    # MTG Arena: fullscreen at the panel's native resolution. Takes effect next launch.
    defaults write com.wizards.mtga "Screenmanager Fullscreen mode" -int 1
    defaults write com.wizards.mtga "Screenmanager Resolution Use Native" -int 1

    """
}
