import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Console → Authentication → Google → Web client ID (OAuth 2.0).
/// Bu değeri kendi Web Client ID kodunuzla değiştirin.
const String googleSignInWebClientId =
    '676323549645-gvm1k7snqa4fp3qa40egdsi85gh0urvv.apps.googleusercontent.com';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(
      serverClientId: googleSignInWebClientId,
    );
    _googleInitialized = true;
  }

  Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    try {
      // Yeni girişten önce önceki hesabı temizle.
      await _googleSignIn.signOut();
    } catch (_) {
      // Bazı cihazlarda ilk denemede oturum olmadığı için hata dönebilir.
    }

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google oturumu yoksa görmezden gel.
    }
    await _auth.signOut();
  }
}
