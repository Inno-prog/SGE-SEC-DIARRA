import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('Plateforme non supportée');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAdup-JatLVH_kcpNLrk5OhnpriV6Svc40',
    appId: '1:223201246269:web:598dc9a748abf4094afe54',
    messagingSenderId: '223201246269',
    projectId: 'sge-sec-diarra',
    authDomain: 'sge-sec-diarra.firebaseapp.com',
    storageBucket: 'sge-sec-diarra.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '<YOUR_ANDROID_API_KEY>',
    appId: '<YOUR_ANDROID_APP_ID>',
    messagingSenderId: '223201246269',
    projectId: 'sge-sec-diarra',
    storageBucket: 'sge-sec-diarra.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '<YOUR_IOS_API_KEY>',
    appId: '<YOUR_IOS_APP_ID>',
    messagingSenderId: '223201246269',
    projectId: 'sge-sec-diarra',
    storageBucket: 'sge-sec-diarra.firebasestorage.app',
    iosBundleId: 'com.secdiarra.sge',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '<YOUR_MACOS_API_KEY>',
    appId: '<YOUR_MACOS_APP_ID>',
    messagingSenderId: '223201246269',
    projectId: 'sge-sec-diarra',
    storageBucket: 'sge-sec-diarra.firebasestorage.app',
    iosBundleId: 'com.secdiarra.sge',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '<YOUR_WINDOWS_API_KEY>',
    appId: '<YOUR_WINDOWS_APP_ID>',
    messagingSenderId: '223201246269',
    projectId: 'sge-sec-diarra',
    storageBucket: 'sge-sec-diarra.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: '<YOUR_LINUX_API_KEY>',
    appId: '<YOUR_LINUX_APP_ID>',
    messagingSenderId: '223201246269',
    projectId: 'sge-sec-diarra',
    storageBucket: 'sge-sec-diarra.firebasestorage.app',
  );
}