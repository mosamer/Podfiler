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
        
        let specRepos = try parseSpecRepos(sections[2])
        
        let specs = try parseSpecChecksums(sections[5])
        Console.debug("SPECS: \(specs.count)")
        
        let podfileChecksum = try parseFileCheckSum(sections[6])
        Console.debug("CHECKSUM: \(podfileChecksum)")
        
        let cocoapodVersion = try parseCocoapodsVersion(sections[7])
        Console.debug("Version: \(cocoapodVersion)")
    }
    
    private func parseSpecRepos(_ section: String) throws -> [String: [String]] {
        let urls = try section
            .match(pattern: "\\s{2}\"?([\\w.\\/@:]+)\"?:") { result in
                section.value(at: result.range(at: 1))
            }
        
        let repos = try urls
            .map { $0.replacingOccurrences(of: "/", with: "\\/")}
            .map { url -> String in
                let pattern = "\\s{2}\"?\(url)\"?:(\\n\\s{4}- ([\\w-]+))+"
                return try section.firstMatch(pattern: pattern, rangeNumber: 0)
            }
            .map { repo in
                try repo.match(pattern: "\\s{4}- ([\\w-]+)") {
                    repo.value(at: $0.range(at: 1))
                }
            }
        
        return zip(urls, repos).reduce(into: [String: [String]]()) { result, item in
            let (url, pods) = item
            result[url] = pods
        }
    }
    private func parseFileCheckSum(_ section: String) throws -> String {
        try section.firstMatch(pattern: "PODFILE CHECKSUM: ([a-f0-9]{40})", rangeNumber: 1)
    }
    
    private func parseCocoapodsVersion(_ section: String) throws -> Version {
        let version = try section.firstMatch(pattern: "COCOAPODS: (\\d+.\\d+.\\d+)", rangeNumber: 1)
        return Version(stringLiteral: String(version))
    }
    
    private func parseSpecChecksums(_ section: String) throws -> [[String: String]] {
        try section.match(pattern: "([\\w-]+): ([a-f0-9]{40})") { result in
            let name = section.value(at: result.range(at: 1))
            let hash = section.value(at: result.range(at: 2))
            return [
                "name": name,
                "hash": hash,
            ]
        }
    }
}

extension String {
    private func fullRange() -> NSRange {
        NSRange(location: 0, length: count)
    }
    
    func value(at range: NSRange) -> String {
        let start = index(startIndex, offsetBy: range.location)
        let end = index(start, offsetBy: range.length)
        return String(self[start..<end])
    }
    
    func match<R>(pattern: String, handler: (NSTextCheckingResult) -> R) throws -> [R] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        var results = [R]()
        regex.enumerateMatches(in: self, options: [], range: fullRange()) { result, _, _ in
            guard let result = result else { return }
            results.append(handler(result))
        }
        return results
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

