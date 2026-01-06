// Placeholder Firebase options file.
// In a real project, run `flutterfire configure` to generate this file
// with your actual Firebase project configuration.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCcw2zHj-VFZ8w9j3NDsOxBLYIQJgYxAd4',
    appId: '1:458645609132:web:b3f12e575f9eed3861dd09',
    messagingSenderId: '458645609132',
    projectId: 'femman-135c4',
    authDomain: 'femman-135c4.firebaseapp.com',
    storageBucket: 'femman-135c4.firebasestorage.app',
  );

  // TODO: Replace these placeholder configs with real values from Firebase.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4dV3hFZJg6vKF6WQZg1clOhZkmwMt_uQ',
    appId: '1:458645609132:android:f8546142214f626e61dd09',
    messagingSenderId: '458645609132',
    projectId: 'femman-135c4',
    storageBucket: 'femman-135c4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    messagingSenderId: 'YOUR_SENDER_ID',
    appId: 'YOUR_IOS_APP_ID',
    iosBundleId: 'com.example.femman',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_DESKTOP_API_KEY',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    messagingSenderId: 'YOUR_SENDER_ID',
    appId: 'YOUR_DESKTOP_APP_ID',
  );
}
