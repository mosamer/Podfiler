import ArgumentParser

struct Podfiler: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "podfiler",
        abstract: "Utilities to process and work with Cocoapods files",
        subcommands: [
        ]
    )

    static func main() {
        do {
            var command = try Podfiler.parseAsRoot()
            try command.run()
        } catch {
            let exitCode = Podfiler.exitCode(for: error).rawValue
            if exitCode == 0 {
                Podfiler.exit(withError: error)
            } else {
                let errorMessage = Podfiler.fullMessage(for: error)
                print(errorMessage)
            }
        }
    }

    func run() throws {
        throw CleanExit.helpRequest(self)
    }
}

Podfiler.main()
