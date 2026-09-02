import AppKit

/// Runs the mode script whenever the mode flips. AppKit's screen-parameters
/// notification prompts an immediate check, and a periodic poll backs it up.
@MainActor
final class Watcher {
    private var last: Mode?
    private var pending: DispatchWorkItem?

    /// Coalesce the burst of notifications a single dock/undock produces.
    private let settle: TimeInterval = 2
    private let pollInterval: TimeInterval = 3

    func run() {
        Log.line("swapper watching displays; scripts in \(Scripts.directory.path)")

        // A faceless app: AppKit delivers display changes to processes with an NSApplication event loop.
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [self] _ in
            MainActor.assumeIsolated { scheduleCheck() }
        }
        Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [self] _ in
            MainActor.assumeIsolated { check() }
        }

        check()
        app.run()
    }

    private func scheduleCheck() {
        pending?.cancel()
        let item = DispatchWorkItem { [self] in
            MainActor.assumeIsolated { check() }
        }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + settle, execute: item)
    }

    private func check() {
        let displays = Display.online()
        let mode = Mode.detect(displays)
        guard mode != last else { return }
        Log.line("\(last.map { "\($0.rawValue) -> " } ?? "")\(mode.rawValue): \(displays.map(\.description).joined(separator: "; "))")
        last = mode
        do {
            try Scripts.run(mode, displays: displays)
        } catch {
            Log.line("error: \(error)")
        }
    }
}
