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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyATjJrWNifc39KcMAdQyRhHYr8zzXlHEhs',
    authDomain: 'promould-ed22a.firebaseapp.com',
    projectId: 'promould-ed22a',
    storageBucket: 'promould-ed22a.firebasestorage.app',
    messagingSenderId: '355780235607',
    appId: '1:355780235607:web:3a10e479c290c210e36e12',
    measurementId: 'G-L9GNF9N2EY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAc4ZY9naIFZzEuhMWOHlj1XEqbTvk1HWY',
    authDomain: 'promould-ed22a.firebaseapp.com',
    projectId: 'promould-ed22a',
    storageBucket: 'promould-ed22a.firebasestorage.app',
    messagingSenderId: '355780235607',
    appId: '1:355780235607:android:66cba16247dd8646e36e12',
    measurementId: 'G-L9GNF9N2EY',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATjJrWNifc39KcMAdQyRhHYr8zzXlHEhs',
    authDomain: 'promould-ed22a.firebaseapp.com',
    projectId: 'promould-ed22a',
    storageBucket: 'promould-ed22a.firebasestorage.app',
    messagingSenderId: '355780235607',
    appId: '1:355780235607:ios:YOUR_IOS_APP_ID',
    measurementId: 'G-L9GNF9N2EY',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyATjJrWNifc39KcMAdQyRhHYr8zzXlHEhs',
    authDomain: 'promould-ed22a.firebaseapp.com',
    projectId: 'promould-ed22a',
    storageBucket: 'promould-ed22a.firebasestorage.app',
    messagingSenderId: '355780235607',
    appId: '1:355780235607:macos:YOUR_MACOS_APP_ID',
    measurementId: 'G-L9GNF9N2EY',
  );
}
