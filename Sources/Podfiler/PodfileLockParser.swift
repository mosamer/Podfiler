import Foundation
import TSCUtility

class PodfileLockParser {
    private let pods: [Pod]
    private let checkouts: [Checkout]
    private let checksums: [String: String]
    init(file: String) throws {
        let sections = file
            .replacingOccurrences(of: "\"", with: "")   // Clean " characters
            .components(separatedBy: "\n\n")            // Separate sections
        
        guard sections.count == 8 else {
            throw "something went wrong. `Podfile.lock` does not lock as expected"
        }
        
        self.pods = try parse(pods: sections[0])
        self.checksums = try parse(checksums: sections[5])
        self.checkouts = try parse(specRepo: sections[2], externalSources: sections[3], checkoutOptions: sections[4])
    }
    
    func generatePodLock() throws -> [PodLock] {
        try checksums.map { name, hash in
            guard let checkout = checkouts.first(where: { $0.name == name }) else {
                throw "can not find matching entry in checkout for <\(name)>"
            }
            guard let podTree = pods.first(where: {$0.name == name || $0.name.hasPrefix("\(name)/") }) else {
                throw "can not find matching entry in pods tree for <\(name)>"
            }

            return PodLock(name: name,
                           checksum: hash,
                           version: podTree.version,
                           source: checkout.source)
        }
    }
    
    struct PodLock {
        let name: String
        let checksum: String
        let version: Version
        let source: CheckoutSource
    }
}
// MARK: Patterns
private enum Pattern {
    // ([+\w\/-]+)
    private static let podName = "([+\\w\\/-]+)"
    // (\d+(.\d+(.\d+(-[\w\d.]+)?)?)?)
    private static let semVer = "(\\d+(.\\d+(.\\d+(-[\\w\\d.]+)?)?)?)"
    // \s{2}- ([+\w\/-]+) \((\d+(.\d+(.\d+(-[\w\d.]+)?)?)?)\)(:(\n\s{4}- ([+\w\/-]+)( \(([=\s\d.>,~<]+)\))?)+)?
    static let podTree = "\\s{2}- \(podName) \\(\(semVer)\\)(:(\(podDependency))+)?"
    // [=\s\d.>,~<]+
    private static let constraint = "[=\\s\\d.>,~<]+"
    // \n\s{4}- ([+\w\/-]+)( \(([=\s\d.>,~<]+)\))?
    static let podDependency = "\\n\\s{4}- \(podName)( \\((\(constraint))\\))?"
    
    // \s{2}([+\w\/-]+):\n(.*\n)?\s{4}:(path|git): ([-.\w:\/@]+)
    static let externalSource = "\\s{2}\(podName):\\n(.*\\n)?\\s{4}:(path|git|http): ([-.\\w:\\/@]+)"
    
    // \s{2}<name>:\n(.*\n)?\s{4}:(commit|tag): ([\w.-]+)
    static func checkoutOption(for name: String) -> String {
        "\\s{2}\(name):\\n(.*\\n)?\\s{4}:(commit|tag): ([\\w.-]+)"
    }
    
    static let checksum = "\(podName): ([a-f0-9]{40})"
    // \s{2}([\w:\/.@]+):
    static let specRepos = "\\s{2}([\\w:\\/.@]+):(\(podInSpec))+"
    // \n\s{4}- ([+\w\/-]+)
    static let podInSpec = "\\n\\s{4}- \(podName)"
}

// MARK: Pods
private struct Pod {
    let name: String
    let version: Version
    let dependencies: [TransitiveDependency]
}
private struct TransitiveDependency {
    let name: String
    let constraint: String?
}

private func parse(pods: String) throws -> [Pod] {
    try pods.match(pattern: Pattern.podTree) { pod in
        let name = try pods.value(from: pod, at: 1)
        let version = try pods.value(from: pod, at: 2)
        let transitives: [TransitiveDependency]
        if let subTree = try? pods.value(from: pod, at: 6) {
            transitives = try subTree
                .match(pattern: Pattern.podDependency) { dependency in
                    TransitiveDependency(
                        name: try subTree.value(from: dependency, at: 1),
                        constraint: try? subTree.value(from: dependency, at: 2)
                    )
                }
        } else {
            transitives = []
        }
        return Pod(name: name, version: Version(stringLiteral: version), dependencies: transitives)
    }
}

// MARK: Spec Repos
private func parse(specRepo: String) throws -> [Checkout] {
    try specRepo
        .match(pattern: Pattern.specRepos) { repo -> (url: String, pods: [String]) in
            let url = try specRepo.value(from: repo, at: 1)
            let repo = try specRepo.value(from: repo, at: 0)
            let pods = try repo.match(pattern: Pattern.podInSpec) { spec in
                try repo.value(from: spec, at: 1)
            }
            return (url: url, pods: pods)
        }
        .map { url, pods in
            pods.map { Checkout(name: $0, source: .specRepo(url)) }
        }
        .flatMap { $0 }
}
// MARK: Checkouts
enum CheckoutSource {
    case path(String)
    case gitTag(String)
    case gitCommit(String)
    case specRepo(String)
    case http(String)
}

private struct Checkout {
    let name: String
    let source: CheckoutSource
}

private func parse(specRepo: String, externalSources: String, checkoutOptions: String) throws -> [Checkout] {
    let checkouts: [Checkout] = try externalSources.match(pattern: Pattern.externalSource) { source in
        let name = try externalSources.value(from: source, at: 1)
        let sourceType = try externalSources.value(from: source, at: 3)
        
        switch sourceType {
        case "path":
            return Checkout(name: name,
                            source: .path(try externalSources.value(from: source, at: 3)))
        case "http":
            return Checkout(name: name,
                            source: .http(try externalSources.value(from: source, at: 3)))
        case "git":
            return try checkoutOptions.firstMatch(pattern: Pattern.checkoutOption(for: name)) { option in
                let type = try checkoutOptions.value(from: option, at: 2)
                let value = try checkoutOptions.value(from: option, at: 3)
                let source: CheckoutSource
                switch type {
                case "commit":
                    source = .gitCommit(value)
                case "tag":
                    source = .gitTag(value)
                default:
                    throw "unrecognized Git external source <\(type)>"
                }
                return Checkout(name: name, source: source)
            }
        default:
            throw "unrecognized external source <\(sourceType)>"
        }
    }
    let specRepos = try specRepo
        .match(pattern: Pattern.specRepos) { repo -> (url: String, pods: [String]) in
            let url = try specRepo.value(from: repo, at: 1)
            let repo = try specRepo.value(from: repo, at: 0)
            let pods = try repo.match(pattern: Pattern.podInSpec) { spec in
                try repo.value(from: spec, at: 1)
            }
            return (url: url, pods: pods)
        }
        .map { url, pods in
            pods.map { Checkout(name: $0, source: .specRepo(url)) }
        }
        .flatMap { $0 }
    
    return checkouts + specRepos
}

// MARK: Checksums
private func parse(checksums: String) throws -> [String: String] {
    try checksums.match(pattern: Pattern.checksum) { line in
        (name: try checksums.value(from: line, at: 1),
         hash: try checksums.value(from: line, at: 2))
    }
    .reduce(into: [String: String]()) { result, item in
        result[item.name] = item.hash
    }
}
