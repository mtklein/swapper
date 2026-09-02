import Foundation

/// Dock auto-hide, changed live through the same private HIServices calls that
/// System Events' `dock preferences` uses. The Dock applies the change immediately
/// and persists it to com.apple.dock itself, so no restart (and no screen flash).
enum Dock {
    private typealias GetAutoHide = @convention(c) () -> Bool
    private typealias SetAutoHide = @convention(c) (Bool) -> Void

    private static let functions: (get: GetAutoHide, set: SetAutoHide)? = {
        let path = "/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/HIServices"
        guard let lib = dlopen(path, RTLD_NOW),
              let get = dlsym(lib, "CoreDockGetAutoHideEnabled"),
              let set = dlsym(lib, "CoreDockSetAutoHideEnabled")
        else { return nil }
        return (unsafeBitCast(get, to: GetAutoHide.self), unsafeBitCast(set, to: SetAutoHide.self))
    }()

    static func autohide() -> Bool {
        if let functions { return functions.get() }
        return UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
    }

    /// Returns true if anything changed.
    @discardableResult
    static func setAutohide(_ enabled: Bool) throws -> Bool {
        guard autohide() != enabled else { return false }
        if let functions {
            functions.set(enabled)
        } else {
            // Private API gone; fall back to the classic restart.
            try Shell.run("/usr/bin/defaults", "write", "com.apple.dock", "autohide", "-bool", String(enabled))
            try Shell.run("/usr/bin/killall", "Dock")
        }
        return true
    }
}
