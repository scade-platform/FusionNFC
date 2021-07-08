# FusionNFC
The FusionNFC SPM package makes it possible to use NFC functionality on Android and iOS using Swift 

Discuss
-------
Join our slack channel here for Fusion Package discussion [link](https://scadeio.slack.com/archives/C025WRG18TW)

For native cross plaform development with Swift and geneel Fusion introduciton, go here [SCADE Fusion](beta.scade.io/fusion)

Install - Add to Package.swift
------------------------------
```swift
import PackageDescription
import Foundation

let SCADE_SDK = ProcessInfo.processInfo.environment["SCADE_SDK"] ?? ""

let package = Package(
    name: "NFCTool",
    platforms: [
        .macOS(.v10_14), .iOS(.v13)
    ],
    products: [
        .library(
            name: "NFCTool",
            type: .static,
            targets: [
                "NFCTool"
            ]
        )
    ],
    dependencies: [
      	.package(name: "FusionNFC", url: "https://github.com/scade-platform/FusionNFC.git", .branch("main"))
    ],
    targets: [
        .target(
            name: "NFCTool",
            dependencies: [
            	.product(name: "FusionNFC", package: "FusionNFC")
            ],
            exclude: ["main.page"],
            swiftSettings: [
                .unsafeFlags(["-F", SCADE_SDK], .when(platforms: [.macOS, .iOS])),
                .unsafeFlags(["-I", "\(SCADE_SDK)/include"], .when(platforms: [.android])),
            ]
        )
    ]
)
```

Permission Settings
-------------------
<Add Permission specific text and instructions>

```yaml
...
ios:
  ...
  entitlements-file: NFCTool.entitlements
  ...
  plist:
    ...
    - key: NFCReaderUsageDescription
      type: string
      value: This app read and write tags
    - key: UIRequiredDeviceCapabilities
      type: list
      value: ["armv7", "nfc"]         

android:
  ...
  manifest-file: AndroidManifest.xml
  permissions: ["NFC"]
  ...
```
 
Entitlements File
-------------------
<Add entitlements>

```yaml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.nfc.readersession.formats</key>
	<array>
		<string>NDEF</string>
		<string>TAG</string>
	</array>
</dict>
</plist>
```

AndroidManifest File
-------------------
<Add AndroidManifest>

```yaml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.scade.rendersvg"
    android:versionCode="1"
    android:versionName="1.0.0" >

    <uses-sdk
        android:minSdkVersion="14"
        android:targetSdkVersion="28" />

    <uses-permission android:name="android.permission.NFC" />

    <uses-feature android:glEsVersion="0x00020000"/>
    <uses-feature android:name="android.hardware.nfc" android:required="true" />

    <application
        android:name="com.scade.phoenix.PhoenixApplication"
        android:allowBackup="false"
        android:icon="@drawable/ic_launcher"
        android:label="RenderSVG"
        android:theme="@android:style/Theme.Black.NoTitleBar">
        <activity
            android:name="com.scade.phoenix.MainActivity"
            android:label="RenderSVG"
            android:windowSoftInputMode="adjustResize|stateHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>


        </activity>
        
        <receiver android:name="FusionNFC_Android.NFCReceiver"/>

        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="AIzaSyAYoreZUQAcxs-Yt18zEAidBSqEuoqnKP4"/>
        <uses-library
            android:name="org.apache.http.legacy"
            android:required="false" />
    </application>

</manifest>
```

Demo App
--------
Our demo app is available here [link](https://github.com/scade-platform/FusionExamples/tree/main/NFCTool)


Basic Usage
-----------
```swift
	...
    var nfcManager: NFCManager?  
  	// page adapter initialization
  	override func load(_ path: String) {
    	super.load(path)

    	// initialize the NFCManager
		nfcManager = NFCManager(alertMessage: "Hold your iPhone near an NFC tag.")

		// connect the button action to read/write func
        self.readButton.onClick{_ in self.read()}
        self.writeButton.onClick{_ in self.write()}

        // Below code is only for Android
	    self.page!.onExit.append(SCDWidgetsExitEventHandler{_ in
	    	self.nfcManager?.disableForegroundDispatch()
        })
  	}
  	
  	// read func
  	func read() {
  		// read NFC Tag
        nfcManager?.readTag { message in

        	// get url and text from NFCMessage
        	guard let message = message else { return }
        	if let uriRecord = message.uriRecord {
        		self.urlLabel.text = "URL: \(uriRecord.url.absoluteString)"
        	}
          	
          	if let textRecord = message.textRecord {
          		self.descriptionLabel.text = "Description: \(textRecord.string)"	
          	}			
        }
    }

    // write func
  	func write() {

  		// prepare the NFCURIRecord from the URL
        var uriRecord: NFCURIRecord?
        if let url = URL(string: urlTextBox.text) {
            uriRecord = NFCURIRecord(url: url)
        }
        
        // prepare the NFCTextRecord from the String and Locale
        let textRecord = NFCTextRecord(string: descriptionTextBox.text, locale: Locale(identifier: "en"))

        // initialize the NFCMessage with NFCURIRecord and NFCTextRecord
        let nfcMessage = NFCMessage(uriRecord: uriRecord, textRecord: textRecord)
        
        // initialize the NFCMessage
        nfcManager = NFCManager(alertMessage: "Hold your iPhone near an NFC tag.")

        // write NFC Tag
        nfcManager?.writeTag(nfcMessage)
    }
    ...
```

Features
--------
List of features
* Read NFC Tag
* Write NFC Tag

API
---
Please find the api here [API](./Sources/FusionNFC_Common/NFCManager.swift)


