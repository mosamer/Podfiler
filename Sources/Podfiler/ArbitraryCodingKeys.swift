import Foundation

public struct ArbitraryCodingKeys: CodingKey, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public typealias StringLiteralType = String
    
    public let stringValue: String
    public init(stringValue: String) {
        self.stringValue = stringValue
    }
    public init(stringLiteral value: String) {
        self.stringValue = value
    }
    
    public var intValue: Int?
    public init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

public extension Decoder {
    func arbitraryContainer() throws -> KeyedDecodingContainer<ArbitraryCodingKeys> {
        try self.container(keyedBy: ArbitraryCodingKeys.self)
    }
}

public extension Encoder {
    func arbitraryContainer() throws -> KeyedEncodingContainer<ArbitraryCodingKeys> {
        self.container(keyedBy: ArbitraryCodingKeys.self)
    }
}
