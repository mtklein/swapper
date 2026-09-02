import AppKit
import CoreGraphics

/// Which physical situation the laptop is in.
enum Mode: String, CaseIterable, Codable {
    case docked
    case mobile

    /// Docked means any online display other than the built-in panel.
    /// Clamshell mode (lid closed, external only) therefore counts as docked.
    static func detect(_ displays: [Display]) -> Mode {
        displays.contains { !$0.builtin } ? .docked : .mobile
    }

    static func detect() -> Mode { detect(Display.online()) }
}

struct Display: CustomStringConvertible {
    let id: CGDirectDisplayID
    let name: String
    let builtin: Bool
    let width: Int
    let height: Int

    var description: String {
        "\(name) \(width)x\(height)\(builtin ? " (built-in)" : "")"
    }

    /// Every display the window server currently knows about, including sleeping ones.
    static func online() -> [Display] {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetOnlineDisplayList(count, &ids, &count)

        let names = Dictionary(
            NSScreen.screens.compactMap { screen -> (CGDirectDisplayID, String)? in
                let key = NSDeviceDescriptionKey("NSScreenNumber")
                guard let number = screen.deviceDescription[key] as? NSNumber else { return nil }
                return (number.uint32Value, screen.localizedName)
            },
            uniquingKeysWith: { first, _ in first }
        )

        return ids.prefix(Int(count)).map { id in
            Display(
                id: id,
                name: names[id] ?? "display \(id)",
                builtin: CGDisplayIsBuiltin(id) != 0,
                width: CGDisplayCopyDisplayMode(id)?.pixelWidth ?? CGDisplayPixelsWide(id),
                height: CGDisplayCopyDisplayMode(id)?.pixelHeight ?? CGDisplayPixelsHigh(id)
            )
        }
    }
}
