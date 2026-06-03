import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDolGCwYtvlqhMDNGkvvi-MdhZvpG-YcFk',
    authDomain: 'akilli-manzil.firebaseapp.com',
    projectId: 'akilli-manzil',
    storageBucket: 'akilli-manzil.firebasestorage.app',
    messagingSenderId: '361380915263',
    appId: '1:361380915263:web:12a35ce285e085ff85b08a',
    measurementId: 'G-CQ87DX1K5V',
  );

  // Replace appId after adding Android app in Firebase Console
  // and downloading google-services.json to android/app/
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDolGCwYtvlqhMDNGkvvi-MdhZvpG-YcFk',
    appId: '1:361380915263:android:REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '361380915263',
    projectId: 'akilli-manzil',
    storageBucket: 'akilli-manzil.firebasestorage.app',
  );
}
