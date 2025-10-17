import Foundation

/// Conditional debug logging - only prints in DEBUG builds
struct DebugLogger {
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(function) - \(message)")
        #endif
    }

    static func success(_ message: String) {
        #if DEBUG
        print("✅ \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("❌ \(message)")
        #endif
    }

    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ \(message)")
        #endif
    }

    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ \(message)")
        #endif
    }
}
