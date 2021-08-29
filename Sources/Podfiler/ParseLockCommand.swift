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
        
    }
}
