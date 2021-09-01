import Foundation

extension String {
    func value(from match: NSTextCheckingResult, at range: Int) throws -> String {
        let nsRange = match.range(at: range)
        guard nsRange.location != NSNotFound, nsRange.length > 0 else { throw "not found" }
        let start = index(startIndex, offsetBy: nsRange.location)
        let end = index(start, offsetBy: nsRange.length)
        return String(self[start..<end])
    }
    
    func match<R>(pattern: String, handler: (NSTextCheckingResult) throws -> R) throws -> [R] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        var results = [NSTextCheckingResult]()
        regex.enumerateMatches(in: self, options: [], range: NSRange(location: 0, length: count)) { result, _, _ in
            guard let match = result else { return }
            results.append(match)
        }
        return try results.map { try handler($0) }
    }
    
    func firstMatch<R>(pattern: String, handler: (NSTextCheckingResult) throws -> R) throws -> R {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) else {
            throw "regex pattern was not matched"
        }
        return try handler(match)
    }
}
