import CoreGraphics
import Foundation

/// Listens for display reconfiguration and runs the mode script whenever the mode flips.
@MainActor
final class Watcher {
    private var last: Mode?
    private var pending: DispatchWorkItem?

    /// Coalesce the burst of callbacks a single dock/undock produces.
    private let settle: TimeInterval = 2

    func run() {
        Log.line("swapper watching displays; scripts in \(Scripts.directory.path)")
        let context = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback({ _, _, userInfo in
            guard let userInfo else { return }
            let watcher = Unmanaged<Watcher>.fromOpaque(userInfo).takeUnretainedValue()
            MainActor.assumeIsolated { watcher.scheduleCheck() }
        }, context)
        check()
        RunLoop.main.run()
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
