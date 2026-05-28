import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import 'admin/admin_cms_app.dart';
import 'firebase_options.dart';
import 'services/admin_firebase_auth.dart';

/// Oyun Editörü — Web veya masaüstü.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.admin);
    try {
      await AdminFirebaseAuth.trySignIn();
    } catch (e) {
      debugPrint('Admin anonim giriş atlandı: $e');
    }
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(AdminBootstrapApp(firebaseError: firebaseError));
}

/// Firebase hatasında bile editör arayüzünü veya net hata mesajını gösterir.
class AdminBootstrapApp extends StatelessWidget {
  const AdminBootstrapApp({super.key, this.firebaseError});

  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    if (firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 56, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Firebase bağlantısı kurulamadı',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      firebaseError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Firebase Console → questalarm → Proje ayarları → '
                      'Web uygulaması ekleyin. `lib/firebase_options.dart` '
                      'içindeki web.appId değerini güncelleyin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const AdminCmsApp();
  }
}
