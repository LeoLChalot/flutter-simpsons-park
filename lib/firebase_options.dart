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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA16sMMlV_o8Lmylwpe_T-vb8CW_YtIWFE',
    appId: '1:282791341945:web:24ea2d4a994acfe6a209a8',
    messagingSenderId: '282791341945',
    projectId: 'flutter-simpsons',
    authDomain: 'flutter-simpsons.firebaseapp.com',
    storageBucket: 'flutter-simpsons.firebasestorage.app',
    measurementId: 'G-D6SC96VHX3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDkjLZKE9Xp98tUe7b4nlAONX_ta0RWBA',
    appId: '1:282791341945:android:7fa4e8a818039d19a209a8',
    messagingSenderId: '282791341945',
    projectId: 'flutter-simpsons',
    storageBucket: 'flutter-simpsons.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA16sMMlV_o8Lmylwpe_T-vb8CW_YtIWFE',
    appId: '1:282791341945:web:ae728259f4b7a415a209a8',
    messagingSenderId: '282791341945',
    projectId: 'flutter-simpsons',
    authDomain: 'flutter-simpsons.firebaseapp.com',
    storageBucket: 'flutter-simpsons.firebasestorage.app',
    measurementId: 'G-4BHW9NCKEJ',
  );

}