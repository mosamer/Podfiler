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
        let result = try parser.generatePodLock()
        print(result.count)
    }
}
