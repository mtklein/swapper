import Foundation

struct SwapperError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

enum Shell {
    /// Runs a program and returns its combined output; throws on a nonzero exit.
    @discardableResult
    static func run(_ program: String, _ arguments: String...) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: program)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard process.terminationStatus == 0 else {
            let command = ([program] + arguments).joined(separator: " ")
            throw SwapperError("`\(command)` exited \(process.terminationStatus)\(text.isEmpty ? "" : ": \(text)")")
        }
        return text
    }
}

@MainActor
enum Log {
    static var timestamps = false

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static func line(_ text: String) {
        if timestamps {
            print("[\(formatter.string(from: Date()))] \(text)")
        } else {
            print(text)
        }
        fflush(stdout)
    }
}
