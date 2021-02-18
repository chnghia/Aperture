import Foundation

struct Options: Decodable {
    let destination: URL
    let framesPerSecond: Int
    let cropRect: CGRect?
    let showCursor: Bool
    let highlightClicks: Bool
    let screenId: CGDirectDisplayID
    let audioDeviceId: String?
    let videoCodec: String?
}

// MARK: - CLI utils
extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(string.data(using: .utf8)!)
    }
}

func synchronized<T>(lock: AnyObject, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    
    return try closure()
}

final class Once {
    private var hasRun = false
    
    /**
     Executes the given closure only once (thread-safe)
     
     ```
     final class Foo {
     private let once = Once()
     
     func bar() {
     once.run {
     print("Called only once")
     }
     }
     }
     
     let foo = Foo()
     foo.bar()
     foo.bar()
     ```
     */
    func run(_ closure: () -> Void) {
        synchronized(lock: self) {
            guard !hasRun else {
                return
            }
            
            hasRun = true
            closure()
        }
    }
}

struct CLI {
    static var standardInput = FileHandle.standardInput
    static var standardOutput = FileHandle.standardOutput
    static var standardError = FileHandle.standardError
    
    static let arguments = Array(CommandLine.arguments.dropFirst(1))
}

extension CLI {
    private static let once = Once()
    
    /// Called when the process exits, either normally or forced (through signals)
    /// When this is set, it's up to you to exit the process
    static var onExit: (() -> Void)? {
        didSet {
            guard let exitHandler = onExit else {
                return
            }
            
            let handler = {
                once.run(exitHandler)
            }
            
            atexit_b {
                handler()
            }
            
            SignalHandler.handle(signals: .exitSignals) { _ in
                handler()
            }
        }
    }
    
    /// Called when the process is being forced (through signals) to exit
    /// When this is set, it's up to you to exit the process
    static var onForcedExit: ((SignalHandler.Signal) -> Void)? {
        didSet {
            guard let exitHandler = onForcedExit else {
                return
            }
            
            SignalHandler.handle(signals: .exitSignals, handler: exitHandler)
        }
    }
}

enum PrintOutputTarget {
    case standardOutput
    case standardError
}

/// Make `print()` accept an array of items
/// Since Swift doesn't support spreading...
private func print<Target>(
    _ items: [Any],
    separator: String = " ",
    terminator: String = "\n",
    to output: inout Target
) where Target: TextOutputStream {
    let item = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(item, terminator: terminator, to: &output)
}

func print(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n",
    to output: PrintOutputTarget = .standardOutput
) {
    switch output {
    case .standardOutput:
        print(items, separator: separator, terminator: terminator)
    case .standardError:
        print(items, separator: separator, terminator: terminator, to: &CLI.standardError)
    }
}

extension Data {
    func jsonDecoded<T: Decodable>() throws -> T {
        return try JSONDecoder().decode(T.self, from: self)
    }
}

extension String {
    func jsonDecoded<T: Decodable>() throws -> T {
        return try data(using: .utf8)!.jsonDecoded()
    }
}

func toJson<T>(_ data: T) throws -> String {
    let json = try JSONSerialization.data(withJSONObject: data)
    return String(data: json, encoding: .utf8)!
}

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }
    
    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
