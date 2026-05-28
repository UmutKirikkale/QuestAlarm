import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Admin CMS — Storage / Firestore yazma için anonim oturum (isteğe bağlı).
class AdminFirebaseAuth {
  AdminFirebaseAuth._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? lastError;

  static User? get currentUser => _auth.currentUser;

  static bool get isSignedIn => _auth.currentUser != null;

  /// Başarısız olursa yükleme yine de açık Storage kurallarıyla denenebilir.
  static Future<bool> trySignIn() async {
    if (_auth.currentUser != null) {
      lastError = null;
      return true;
    }
    try {
      await _auth.signInAnonymously();
      lastError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = '${e.code}: ${e.message ?? ''}';
      debugPrint('AdminFirebaseAuth: $lastError');
      return false;
    } catch (e) {
      lastError = e.toString();
      debugPrint('AdminFirebaseAuth: $e');
      return false;
    }
  }

  static Future<void> ensureSignedIn() async {
    final ok = await trySignIn();
    if (!ok) {
      throw StateError(
        lastError ??
            'Anonim giriş başarısız. Firebase Console → Authentication → '
            'Anonymous → Enable. (Storage kuralları açıksa yükleme yine çalışabilir.)',
      );
    }
  }
}
