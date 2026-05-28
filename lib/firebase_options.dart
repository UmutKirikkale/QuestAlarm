// Firebase yapılandırması.
//
// Web Admin için: Firebase Console → Proje ayarları → Web uygulaması ekle.
// Ardından `appId` değerini [web] bölümünde güncelleyin veya:
//   flutterfire configure --project=questalarm

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Varsayılan [FirebaseOptions] — mobil uygulama (Android).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS henüz yapılandırılmadı.');
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return adminDesktop;
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Desteklenmeyen platform.');
    }
  }

  /// Admin CMS (web tarayıcı).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDF9btbYFLiK8wUxsXtQ5UaWMTW1Od891M',
    appId: '1:676323549645:web:questalarm_admin',
    messagingSenderId: '676323549645',
    projectId: 'questalarm',
    authDomain: 'questalarm.firebaseapp.com',
    storageBucket: 'questalarm.firebasestorage.app',
  );

  /// Admin CMS (masaüstü).
  static const FirebaseOptions adminDesktop = FirebaseOptions(
    apiKey: 'AIzaSyDF9btbYFLiK8wUxsXtQ5UaWMTW1Od891M',
    appId: '1:676323549645:android:196a267e1c97fa0cc86484',
    messagingSenderId: '676323549645',
    projectId: 'questalarm',
    storageBucket: 'questalarm.firebasestorage.app',
  );

  /// Admin girişi — web veya masaüstü.
  static FirebaseOptions get admin => kIsWeb ? web : adminDesktop;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDF9btbYFLiK8wUxsXtQ5UaWMTW1Od891M',
    appId: '1:676323549645:android:196a267e1c97fa0cc86484',
    messagingSenderId: '676323549645',
    projectId: 'questalarm',
    storageBucket: 'questalarm.firebasestorage.app',
  );
}
