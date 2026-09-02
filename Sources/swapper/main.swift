import Foundation

let usage = """
    usage: swapper <command>

      status               show detected mode, displays, scripts, and agent state
      dock-autohide [on|off]
                           show or set Dock auto-hide live, without restarting the Dock
      run [docked|mobile]  run the script for a mode (default: the detected mode)
      watch                stay running and run the script whenever the mode changes
      init                 write example scripts to ~/.config/swapper/ (never overwrites)
      install              install and start a launchd agent that runs `swapper watch`
      uninstall            stop and remove the launchd agent

    Mode is "docked" when any display other than the built-in panel is online,
    otherwise "mobile". Scripts receive $SWAPPER_MODE and $SWAPPER_DISPLAYS.
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("swapper: \(message)\n".utf8))
    exit(1)
}

func parseMode(_ text: String?) -> Mode {
    guard let text else { return Mode.detect() }
    guard let mode = Mode(rawValue: text) else {
        fail("unknown mode '\(text)'; expected docked or mobile")
    }
    return mode
}

let arguments = Array(CommandLine.arguments.dropFirst())

switch arguments.first {
case nil, "help", "-h", "--help":
    print(usage)

case "status":
    let displays = Display.online()
    let mode = Mode.detect(displays)
    print("mode:     \(mode.rawValue)")
    for display in displays {
        print("display:  \(display)")
    }
    for candidate in Mode.allCases {
        let url = Scripts.url(for: candidate)
        let exists = FileManager.default.fileExists(atPath: url.path)
        print("\(candidate.rawValue.padding(toLength: 9, withPad: " ", startingAt: 0)) \(url.path)\(exists ? "" : "  (missing)")")
    }
    print("agent:    \(LaunchAgent.isLoaded ? "running" : "not installed")  \(LaunchAgent.plistURL.path)")
    print("log:      \(LaunchAgent.logURL.path)")

case "dock-autohide":
    switch arguments.dropFirst().first {
    case nil:
        print(Dock.autohide() ? "on" : "off")
    case "on", "true", "1", "yes":
        do { try Dock.setAutohide(true) } catch { fail("\(error)") }
    case "off", "false", "0", "no":
        do { try Dock.setAutohide(false) } catch { fail("\(error)") }
    case let value?:
        fail("expected on or off, got '\(value)'")
    }

case "run":
    let displays = Display.online()
    let mode = arguments.count > 1 ? parseMode(arguments[1]) : Mode.detect(displays)
    do {
        try Scripts.run(mode, displays: displays)
    } catch {
        fail("\(error)")
    }

case "watch":
    Log.timestamps = true
    Watcher().run()

case "init":
    do {
        let written = try Scripts.writeExamples()
        if written.isEmpty {
            print("scripts already exist in \(Scripts.directory.path); nothing written")
        }
        for url in written {
            print("wrote \(url.path)")
        }
    } catch {
        fail("\(error)")
    }

case "install":
    guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() else {
        fail("cannot determine path to this executable")
    }
    do {
        try LaunchAgent.install(executable: executable)
        print("installed \(LaunchAgent.plistURL.path)")
        print("running   \(executable.path) watch")
        print("log       \(LaunchAgent.logURL.path)")
    } catch {
        fail("\(error)")
    }

case "uninstall":
    do {
        try LaunchAgent.uninstall()
        print("removed \(LaunchAgent.plistURL.path)")
    } catch {
        fail("\(error)")
    }

case let command?:
    fail("unknown command '\(command)'\n\(usage)")
}
