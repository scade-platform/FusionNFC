import FusionNFC_Common
import CoreNFC

public class NFCManager {
    fileprivate class NDEFDelegate: NSObject {
        typealias Receiver = (NFCMessage?) -> Void
        var receiver: Receiver?
        var usage: SessionUsage = .none
        var ndefMessage: NFCNDEFMessage?
    }
  
    private let delegate: NDEFDelegate
    private var readerSession: NFCNDEFReaderSession?
    
    public required init(alertMessage: String) {
        self.delegate = NDEFDelegate()
        readerSession = NFCNDEFReaderSession(delegate: self.delegate, queue: nil, invalidateAfterFirstRead: false)
        readerSession?.alertMessage = alertMessage
    }
}

extension NFCManager: NFCManagerProtocol {
    public static var readingAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }
    
    public func readTag(_ completion: @escaping (NFCMessage?) -> Void) {
        guard let session = readerSession else {
            completion(nil)
            return
        }
        if NFCManager.readingAvailable {
            self.delegate.receiver = completion
            self.delegate.usage = .read
            session.begin()
        } else {
            session.invalidate(errorMessage: "This device doesn't support tag scanning.")
            completion(nil)
        }
    }
    
    public func writeTag(_ message: NFCMessage) {
        guard let session = readerSession else {
            return
        }
        if NFCManager.readingAvailable {
            self.delegate.usage = .write
            
            var payloads: [NFCNDEFPayload] = []
            
            if let uriRecord = message.uriRecord {
                if let uriPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: uriRecord.url) {
                    payloads.append(uriPayload)
                }
            }
            
            if let textRecord = message.textRecord {
                if let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
                    string: textRecord.string,
                    locale: textRecord.locale
                ) {
                    payloads.append(textPayload)
                }
            }

            if !payloads.isEmpty {
                self.delegate.ndefMessage = NFCNDEFMessage(records: payloads)
            }
            
            session.begin()
        } else {
            session.invalidate(errorMessage: "This device doesn't support tag scanning.")
        }
    }
    
    public func disableForegroundDispatch() {
	}
}

extension NFCManager.NDEFDelegate: NFCNDEFReaderSessionDelegate {
    // MARK: - NFCNDEFReaderSessionDelegate
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // If necessary, you may handle the error. Note session is no longer valid.
        // You must create a new session to restart RF polling.
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Do not add code in this function. This method isn't called
        // when you provide `reader(_:didDetect:)`.
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            session.alertMessage = "More than 1 tags found. Please present only 1 tag."
            self.tagRemovalDetect(session, tags.first!)
            return
        }

        // You connect to the desired tag.
        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
            if error != nil {
                session.restartPolling()
                return
            }

            // You then query the NDEF status of tag.
            tag.queryNDEFStatus() { (status: NFCNDEFStatus, capacity: Int, error: Error?) in
                if error != nil {
                    session.invalidate(errorMessage: "Fail to determine NDEF status.  Please try again.")
                    return
                }
                
                if self.usage == .write {
                    if status == .readOnly {
                        session.invalidate(errorMessage: "Tag is not writable.")
                    } else if status == .readWrite {
                        if self.ndefMessage!.length > capacity {
                            session.invalidate(errorMessage: "Tag capacity is too small.  Minimum size requirement is \(self.ndefMessage!.length) bytes.")
                            return
                        }

                        // When a tag is read-writable and has sufficient capacity,
                        // write an NDEF message to it.
                        tag.writeNDEF(self.ndefMessage!) { (error: Error?) in
                            if error != nil {
                                session.invalidate(errorMessage: "Update tag failed. Please try again.")
                            } else {
                                session.alertMessage = "Update success!"
                                session.invalidate()
                            }
                        }
                    } else {
                        session.invalidate(errorMessage: "Tag is not NDEF formatted.")
                    }
                } else if self.usage == .read {
                    if status == .notSupported {
                        session.invalidate(errorMessage: "Tag not valid.")
                        self.receiver?(nil)
                        return
                    }
                    tag.readNDEF() { (message: NFCNDEFMessage?, error: Error?) in
                        guard let message = message, error == nil else {
                            session.invalidate(errorMessage: "Read error. Please try again.")
                            self.receiver?(nil)
                            return
                        }
                        
                        let nfcMessage = self.convert(ndefMessage: message)
                        if nfcMessage.textRecord != nil || nfcMessage.uriRecord != nil {
                            session.alertMessage = "Tag read success."
                            session.invalidate()
                            self.receiver?(nfcMessage)
                            return
                        } else {
                            session.alertMessage = "Tag read success but no data"
                            session.invalidate()
                            self.receiver?(nil)
                            return
                        }
                    }
                }
            }
        }
    }
    
    func tagRemovalDetect(_ session: NFCNDEFReaderSession, _ tag: NFCNDEFTag) {
        // In the tag removal procedure, you connect to the tag and query for
        // its availability. You restart RF polling when the tag becomes
        // unavailable; otherwise, wait for certain period of time and repeat
        // availability checking.
        session.connect(to: tag) { (error: Error?) in
            if error != nil || !tag.isAvailable {
                session.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
                self.tagRemovalDetect(session, tag)
            })
        }
    }
    
    func convert(ndefMessage: NFCNDEFMessage) -> NFCMessage {
        let urls: [URL] = ndefMessage.records.compactMap { (payload: NFCNDEFPayload) -> URL? in
            if let url = payload.wellKnownTypeURIPayload() {
                return url
            }
            return nil
        }
        
        var nfcURIRecord: NFCURIRecord?
        var nfcTextRecord: NFCTextRecord?
        
        if !urls.isEmpty, let url = urls.first {
            nfcURIRecord = NFCURIRecord(url: url)
        }
        
        var additionInfo: String? = nil
        var locale: Locale?
        
        for payload in ndefMessage.records {
            (additionInfo, locale) = payload.wellKnownTypeTextPayload()
            
            if let additionInfo = additionInfo, let locale = locale {
                nfcTextRecord = NFCTextRecord(string: additionInfo, locale: locale)
                break
            }
        }
        
        return NFCMessage(uriRecord: nfcURIRecord, textRecord: nfcTextRecord)
    }
}
