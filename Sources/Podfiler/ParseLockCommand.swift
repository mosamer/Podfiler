import Foundation
import ArgumentParser
import TSCBasic
import TSCUtility

struct ParseLockCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
            commandName: "parse-lock",
            abstract: "Parse a given `Podfile.lock` file"
        )
        
    @Option(
        name: .customLong("lock"),
        help: "Path to `Podfile.lock` to parse",
        completion: .file(extensions: ["lock"])
    )
    var lockPath: AbsolutePath
    
    func run() throws {
        Console.debug("reading lock file from: \(lockPath.pathString)")
        
        let lock = try lockPath.read()
        let sections = lock.components(separatedBy: "\n\n")
        guard sections.count == 8 else {
            throw "something went wrong. `Podfile.lock` does not lock as expected"
        }
        
        let cocoapodVersion = try parseCocoapodsVersion(sections[7])
        Console.debug("Version: \(cocoapodVersion)")
    }
    
    private func parseCocoapodsVersion(_ section: String) throws -> Version {
        let version = try section.firstMatch(pattern: "COCOAPODS: (\\d+.\\d+.\\d+)", rangeNumber: 1)
        return Version(stringLiteral: String(version))
    }
}

extension String {
    private func fullRange() -> NSRange {
        NSRange(location: 0, length: count)
    }
    
    func firstMatch(pattern: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex.firstMatch(in: self, options: [], range: fullRange()) else {
            throw "regex pattern was not matched"
        }
        return (1...match.numberOfRanges)
            .map { index in
                match.range(at: index)
            }
            .filter { $0.location != NSNotFound }
            .map { range -> String in
                let start = index(startIndex, offsetBy: range.location)
                let end = index(start, offsetBy: range.length)
                return String(self[start..<end])
            }
    }
    
    func firstMatch(pattern: String, rangeNumber: Int) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex.firstMatch(in: self, options: [], range: fullRange()) else {
            throw "regex pattern was not matched"
        }
        let range = match.range(at: rangeNumber)
        guard range.location != NSNotFound else {
            throw "range was not found"
        }
        let start = index(startIndex, offsetBy: range.location)
        let end = index(start, offsetBy: range.length)
        return String(self[start..<end])
    }
}
