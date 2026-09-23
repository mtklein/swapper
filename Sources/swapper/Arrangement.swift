import CoreGraphics

/// Which side of the main external display the built-in panel sits on in the
/// display arrangement.
enum Arrangement {
    enum Side: String {
        case left
        case right
    }

    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    private static func displays() throws -> (builtin: CGDirectDisplayID, external: CGDirectDisplayID) {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        let active = ids.prefix(Int(count))
        guard let builtin = active.first(where: { CGDisplayIsBuiltin($0) != 0 }) else {
            throw Failure(description: "the built-in display is not active")
        }
        guard let external = active.first(where: { CGDisplayIsBuiltin($0) == 0 }) else {
            throw Failure(description: "no external display is active")
        }
        return (builtin, external)
    }

    static func side() throws -> Side {
        let (builtin, external) = try displays()
        return CGDisplayBounds(builtin).midX < CGDisplayBounds(external).midX ? .left : .right
    }

    /// Moves the built-in panel flush against the given edge of the external
    /// display, keeping its vertical offset, and saves the arrangement.
    static func setSide(_ side: Side) throws {
        let (builtin, external) = try displays()
        let panel = CGDisplayBounds(builtin)
        let screen = CGDisplayBounds(external)
        let x = side == .left ? screen.minX - panel.width : screen.maxX
        guard panel.minX != x else { return }

        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else {
            throw Failure(description: "could not begin display configuration")
        }
        CGConfigureDisplayOrigin(config, builtin, Int32(x), Int32(panel.minY))
        let result = CGCompleteDisplayConfiguration(config, .permanently)
        guard result == .success else {
            throw Failure(description: "display configuration failed (\(result.rawValue))")
        }
    }
}
