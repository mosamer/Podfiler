import Foundation

class PodfileLockParser {
    init(file: String) throws {
        let sections = file
            .replacingOccurrences(of: "\"", with: "")   // Clean " characters
            .components(separatedBy: "\n\n")            // Separate sections
        
        guard sections.count == 8 else {
            throw "something went wrong. `Podfile.lock` does not lock as expected"
        }
        
        let match: [String] = try sections[0].match(pattern: Pattern.podTree) { match in
            let pods = sections[0]
            let podName = pods.value(at: match.range(at: 1))
            let podVersion = pods.value(at: match.range(at: 2))
            if match.range(at: 6).location != NSNotFound {
                let podDeps = pods.value(at: match.range(at: 6))
                let deps: [String] = try podDeps.match(pattern: Pattern.podDependency) { dep in
                    let full = podDeps
                    let dependencyName = podDeps.value(at: dep.range(at: 1))
                    if dep.range(at: 2).location != NSNotFound {
                        let constraintType = podDeps.value(at: dep.range(at: 4))
                        let constraintVersion = podDeps.value(at: dep.range(at: 5))
                        return ""
                    }
                    return ""
                }
            } else {
                
            }
            return ""
        }
        print(match.count)
    }
    
    private enum Pattern {
        // ([\w\/-]+)
        static let podName = "([+\\w\\/-]+)"
        // (\d+(.\d+(.\d+(-[\w\d.]+)?)?)?)
        static let semVer = "(\\d+(.\\d+(.\\d+(-[\\w\\d.]+)?)?)?)"
        // \s{2}- ([\w\/-]+) \((\d+(.\d+(.\d+(-[\w\d.]+)?)?)?)\)(:(\n\s{4}- ([\w\/-]+)( \(((~>|=) )?(\d+(.\d+(.\d+(-[\w\d.]+)?)?)?)\))?)+)?
        static let podTree = "\\s{2}- \(podName) \\(\(semVer)\\)(:(\(podDependency))+)?"
        
        static let podDependency = "\\n\\s{4}- \(podName)( \\(((~>|=) )?\(semVer)\\))?"
    }
}
