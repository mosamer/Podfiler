import Foundation
import TSCUtility

class PodfileLockParser {
    private let pods: [Pod]
    init(file: String) throws {
        let sections = file
            .replacingOccurrences(of: "\"", with: "")   // Clean " characters
            .components(separatedBy: "\n\n")            // Separate sections
        
        guard sections.count == 8 else {
            throw "something went wrong. `Podfile.lock` does not lock as expected"
        }
        
        self.pods = try PodfileLockParser.parse(pods: sections[0])
        
        print(pods.count)
    }
}

// MARK: Patterns
private enum Pattern {
    // ([+\w\/-]+)
    static let podName = "([+\\w\\/-]+)"
    // (\d+(.\d+(.\d+(-[\w\d.]+)?)?)?)
    static let semVer = "(\\d+(.\\d+(.\\d+(-[\\w\\d.]+)?)?)?)"
    // \s{2}- ([+\w\/-]+) \((\d+(.\d+(.\d+(-[\w\d.]+)?)?)?)\)(:(\n\s{4}- ([+\w\/-]+)( \(([=\s\d.>,~<]+)\))?)+)?
    static let podTree = "\\s{2}- \(podName) \\(\(semVer)\\)(:(\(podDependency))+)?"
    // [=\s\d.>,~<]+
    private static let constraint = "[=\\s\\d.>,~<]+"
    // \n\s{4}- ([+\w\/-]+)( \(([=\s\d.>,~<]+)\))?
    static let podDependency = "\\n\\s{4}- \(podName)( \\((\(constraint))\\))?"
}

// MARK: Pods Section
private extension PodfileLockParser {
    struct Pod {
        let name: String
        let version: Version
        let dependencies: [TransitiveDependency]
    }
    struct TransitiveDependency {
        let name: String
        let constraint: String?
    }
    
    static func parse(pods: String) throws -> [Pod] {
        try pods.match(pattern: Pattern.podTree) { pod in
            let name = try pods.value(at: pod.range(at: 1))
            let version = try pods.value(at: pod.range(at: 2))
            let transitives: [TransitiveDependency]
            if let subTree = try? pods.value(at: pod.range(at: 6)) {
                transitives = try subTree
                    .match(pattern: Pattern.podDependency) { dependency in
                        TransitiveDependency(
                            name: try subTree.value(at: dependency.range(at: 1)),
                            constraint: try? subTree.value(at: dependency.range(at: 2))
                        )
                    }
            } else {
                transitives = []
            }
            return Pod(name: name, version: Version(stringLiteral: version), dependencies: transitives)
        }
    }
}
