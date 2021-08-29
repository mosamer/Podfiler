import Foundation

struct Console {
    static func debug(_ message: Any) {
        print("🔍 \(message)")
    }
    static func error(_ message: Any) {
        print("⛔️ \(message)")
    }
}
