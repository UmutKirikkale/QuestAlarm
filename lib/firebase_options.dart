// Firebase yapılandırması.
//
// Gerçek projeniz için:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Bu dosya yer tutucu değerlerle CI derlemesini destekler; Analytics/Crashlytics
// için Firebase Console'dan indirdiğiniz google-services.json ile güncelleyin.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Varsayılan [FirebaseOptions] — yalnızca Android hedeflenir.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'QuestAlarm web üzerinde Firebase kullanmıyor.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'QuestAlarm yalnızca Android için yapılandırıldı.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDF9btbYFLiK8wUxsXtQ5UaWMTW1Od891M',
    appId: '1:676323549645:android:196a267e1c97fa0cc86484',
    messagingSenderId: '676323549645',
    projectId: 'questalarm',
    storageBucket: 'questalarm.firebasestorage.app',
  );

}