import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfc3VVzEF_-fH3q3d9n2fJuOOSYzGdonw',
    appId: '1:775503499176:android:a84a7373d6d9a47af6579d',
    messagingSenderId: '775503499176',
    projectId: 'livelyapp-83181',
    storageBucket: 'livelyapp-83181.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2VBNPct87N8O6IPO-I-GfdFtmrw_4nnQ',
    appId: '1:775503499176:ios:93ecb119147fed79f6579d',
    messagingSenderId: '775503499176',
    projectId: 'livelyapp-83181',
    storageBucket: 'livelyapp-83181.firebasestorage.app',
    iosBundleId: 'com.arzuman.livelyapp',
  );

  // TODO: Register a Web app in Firebase Console for a proper web API key
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCfc3VVzEF_-fH3q3d9n2fJuOOSYzGdonw',
    appId: '1:775503499176:android:a84a7373d6d9a47af6579d',
    messagingSenderId: '775503499176',
    projectId: 'livelyapp-83181',
    storageBucket: 'livelyapp-83181.firebasestorage.app',
    authDomain: 'livelyapp-83181.firebaseapp.com',
  );
}
