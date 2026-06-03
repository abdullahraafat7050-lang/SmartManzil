import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Add google-services.json and run flutterfire configure for Android
        throw UnsupportedError(
            'Android Firebase config not set up. Run: flutterfire configure');
      case TargetPlatform.iOS:
        throw UnsupportedError(
            'iOS Firebase config not set up. Run: flutterfire configure');
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
  );
}
