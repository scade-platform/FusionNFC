import Foundation

public struct NFCMessage {
    public let uriRecord: NFCURIRecord?
    public let textRecord: NFCTextRecord?
    
    public init(uriRecord: NFCURIRecord?, textRecord: NFCTextRecord?) {
        self.uriRecord = uriRecord
        self.textRecord = textRecord
    }
}

public struct NFCURIRecord {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
}

public struct NFCTextRecord {
    public let string: String
    public let locale: Locale
    
    public init(string: String, locale: Locale) {
        self.string = string
        self.locale = locale
    }
}

public enum SessionUsage {
    case none
    case read
    case write
}

public protocol NFCManagerProtocol {
    init(alertMessage: String)    
    
    static var readingAvailable: Bool { get }
    func readTag(_ completion: @escaping (NFCMessage?) -> Void)
    func writeTag(_ message: NFCMessage)
    
    func disableForegroundDispatch()
}