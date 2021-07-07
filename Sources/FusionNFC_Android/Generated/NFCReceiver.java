package FusionNFC_Android;

public class NFCReceiver extends android.content.BroadcastReceiver {
  private long _ptr;
  
  public void onReceive(android.content.Context context, android.content.Intent intent) {
    onReceiveImpl(_ptr ,context ,intent);
  }
  private native void onReceiveImpl(long _ptr, android.content.Context context, android.content.Intent intent);
  
}
