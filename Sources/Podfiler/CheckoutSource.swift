import Foundation

enum CheckoutSource {
    case path(String)
    case gitTag(String, url: String)
    case gitCommit(String, url: String)
    case specRepo(String)
    case http(String)
}

extension CheckoutSource: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = try encoder.arbitraryContainer()
        
        switch self {
        case let .path(path):
            try container.encode(path, forKey: "path")
        case let .http(url):
            try container.encode(url, forKey: "http")
        default:
            break
        }
    }
}
