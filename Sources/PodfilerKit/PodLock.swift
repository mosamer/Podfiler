import Foundation
import TSCUtility

public struct PodLock {
    let name: String
    let checksum: String
    let version: Version
    let source: CheckoutSource
}

extension PodLock: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = try encoder.arbitraryContainer()
        
        var nested = container.nestedContainer(keyedBy: ArbitraryCodingKeys.self, forKey: "\(name)")
        
        try nested.encode(checksum, forKey: "checksum")
        try nested.encode(version, forKey: "version")
        switch source {
        case let .path(path):
            try nested.encode(path, forKey: "path")
        case let .http(url):
            try nested.encode(url, forKey: "http")
        case let .gitTag(tag, url):
            try nested.encode(url, forKey: "git")
            try nested.encode(tag, forKey: "tag")
        case let .gitCommit(commit, url):
            try nested.encode(url, forKey: "git")
            try nested.encode(commit, forKey: "commit")
        case let .specRepo(repo):
            try nested.encode(repo, forKey: "spec")
        }
    }
}
