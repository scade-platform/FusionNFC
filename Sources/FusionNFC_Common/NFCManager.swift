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
    public var url: URL
    public var urlType: URLType?
    
    public init(url: URL) {
        self.url = url
    }
    
    public init(url: URL, urlType: URLType) {
        self.url = url
        self.urlType = urlType
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

public enum URLType {
    case website
    case email
    case sms
    case phone
    case facetime
    case shortcut
    case default_text
}

public protocol NFCManagerProtocol {
    /*
     *  Creates and returns a new NFCManager object initialized with the Alert Message.
     *  
     *  Parameters:  alertMessage    	It targets only for iOS. 
     */
    init(alertMessage: String)    
    
    /*
     * @property readingAvailable
     *
     * @discussion YES if device supports NFC tag reading.
     */    
    static var readingAvailable: Bool { get }
    
    /*
     * @method readTag:
     *
     * @param completion Returns the NFCMessage from read operation.  Successful read would return a valid NFCMessage objectl;
     *                          read failure returns a nil NFCMessage.
     *
     * @discussion Reads NFC message from the tag.
     */    
    func readTag(_ completion: @escaping (NFCMessage?) -> Void)
    
    /*
     * @method writeTag:
     *
     * @param message  NFCMessage.
     *
     * @discussion Writes a NFC message to the tag.
     */
    func writeTag(_ message: NFCMessage)
    
    /*
     * @method disableForegroundDispatch:
     *
     * @discussion It targets only for Android.
     */    
    func disableForegroundDispatch()
}
