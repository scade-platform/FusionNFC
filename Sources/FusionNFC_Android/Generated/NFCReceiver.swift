#if os(Android)

import Java
import Android
import AndroidOS
import AndroidApp
import AndroidContent
import AndroidNFC

@_silgen_name("Java_FusionNFC_1Android_NFCReceiver_onReceiveImpl")
public func NFCReceiver_onReceiveImpl(env: UnsafeMutablePointer<JNIEnv>, obj: JavaObject?, ptr: JavaLong, context: JavaObject?, intent: JavaObject?) -> Void { 
  	let _context = cast(Object?.fromJavaObject(context), to: ContextProxy.self)
  	let _intent = Intent?.fromJavaObject(intent)
  
	NFCReceiver.didReceive(context: _context, intent: _intent)
}

#endif
