import Foundation
import ArgumentParser
import TSCBasic
import TSCUtility
import Yams
import PodfilerKit

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
    
    @Option(
        help: "Path to write generated lock to"
    )
    var output: AbsolutePath
    
    func run() throws {
        Console.debug("reading lock file from: \(lockPath.pathString)")
        
        let lock = try lockPath.read()
        let parser = try PodfileLockParser(file: lock)
        let result = try parser.generatePodLock()
        
        let encoder = YAMLEncoder()
        let yml = try encoder.encode(result)
        try output.write(yml)
    }
}
