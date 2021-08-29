import Foundation
import TSCBasic
import ArgumentParser

public extension AbsolutePath {
    func read() throws -> String {
        try String(contentsOf: asURL, encoding: .utf8)
    }
    
    func write(_ content: String) throws {
        let manager = FileManager.default
        if !manager.fileExists(atPath: dirname) {
            try manager.createDirectory(
                atPath: dirname,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        try content.write(to: asURL, atomically: true, encoding: .utf8)
    }
}

extension KeyedDecodingContainer {
    public func decodePath(forKey key: Key) throws -> AbsolutePath {
        let path = try decode(String.self, forKey: key)
        return try AbsolutePath(pathStr: path)
    }
}

extension AbsolutePath: ExpressibleByArgument {
    init(pathStr: String) throws {
        switch pathStr.first {
        case "/":
            self.init(pathStr)
        case "~":
            if #available(macOS 10.12, *) {
                let home = AbsolutePath(FileManager.default.homeDirectoryForCurrentUser.path)
                self.init("\(pathStr.dropFirst(2))", relativeTo: home)
            } else {
                fallthrough
            }
        default:
            let current = AbsolutePath(FileManager.default.currentDirectoryPath)
            self.init(pathStr, relativeTo: current)
        }
    }
    
    public init?(argument path: String) {
        try? self.init(pathStr: path)
    }
}

