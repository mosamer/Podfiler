import Foundation
import ArgumentParser
import TSCBasic

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
    }
}
