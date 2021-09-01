import Foundation

struct ArbitraryCodingKeys: CodingKey, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    typealias StringLiteralType = String
    
    let stringValue: String
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    init(stringLiteral value: String) {
        self.stringValue = value
    }
    
    var intValue: Int?
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension Decoder {
    func arbitraryContainer() throws -> KeyedDecodingContainer<ArbitraryCodingKeys> {
        try self.container(keyedBy: ArbitraryCodingKeys.self)
    }
}

extension Encoder {
    func arbitraryContainer() throws -> KeyedEncodingContainer<ArbitraryCodingKeys> {
        self.container(keyedBy: ArbitraryCodingKeys.self)
    }
}
