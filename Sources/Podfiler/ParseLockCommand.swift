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
        let parser = try PodfileLockParser(file: lock)
        let sections = lock.components(separatedBy: "\n\n")
        guard sections.count == 8 else {
            throw "something went wrong. `Podfile.lock` does not lock as expected"
        }
        
        let specRepos = try parseSpecRepos(sections[2])
            .flatMap { url, repos in
                repos.map { (podName: $0, repo: url) }
            }
    }
    
    private func parseSpecRepos(_ section: String) throws -> [String: [String]] {
        let urls = try section
            .match(pattern: "\\s{2}\"?([\\w.\\/@:]+)\"?:") { result in
                try section.value(at: result.range(at: 1))
            }
        
        let repos = try urls
            .map { $0.replacingOccurrences(of: "/", with: "\\/")}
            .map { url -> String in
                let pattern = "\\s{2}\"?\(url)\"?:(\\n\\s{4}- ([\\w-]+))+"
                return try section.firstMatch(pattern: pattern, rangeNumber: 0)
            }
            .map { repo in
                try repo.match(pattern: "\\s{4}- ([\\w-]+)") {
                    try repo.value(at: $0.range(at: 1))
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
            let name = try section.value(at: result.range(at: 1))
            let hash = try section.value(at: result.range(at: 2))
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
    
    func value(at range: NSRange) throws  -> String {
        guard range.location != NSNotFound, range.length > 0 else { throw "not found" }
        let start = index(startIndex, offsetBy: range.location)
        let end = index(start, offsetBy: range.length)
        return String(self[start..<end])
    }
    
    func match<R>(pattern: String, handler: (NSTextCheckingResult) throws -> R) throws -> [R] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        var results = [R]()
        regex.enumerateMatches(in: self, options: [], range: fullRange()) { result, _, _ in
            guard let result = result,
            let item = try? handler(result) else { return }
            results.append(item)
        }
        return results
    }
    
    func firstMatch<R>(pattern: String, handler: (NSTextCheckingResult) throws -> R) throws -> R {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex.firstMatch(in: self, options: [], range: fullRange()) else {
            throw "regex pattern was not matched"
        }
        return try handler(match)
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

struct Pod_ {
    let name: String
    
    enum Source {
        case path(String)
        case gitTag(String)
        case gitCommit(String)
    }
    let source: Source
}

extension NSRange {
    var isFound: Bool {
        location != NSNotFound && length > 0
    }
}
