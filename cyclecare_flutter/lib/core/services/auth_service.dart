import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  bool get isSignedIn => currentUser != null;

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final userCredential = await _firebaseAuth.signInWithPopup(provider);
        return userCredential.user;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_friendlyFirebaseAuthMessage(e), e);
    } catch (e) {
      throw AuthServiceException(
        'Google sign-in is not available right now. Please check your Firebase OAuth configuration and try again.',
        e,
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;
    await user.delete();
    await _googleSignIn.signOut();
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

String _friendlyFirebaseAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'popup-closed-by-user':
    case 'canceled':
      return 'Sign in was cancelled.';
    case 'network-request-failed':
      return 'Network error. Please check your connection and try again.';
    case 'operation-not-allowed':
      return 'Google sign-in is not enabled in Firebase Authentication.';
    case 'invalid-credential':
    case 'account-exists-with-different-credential':
      return 'This Google account cannot be used with the current Firebase configuration.';
    default:
      return e.message ?? 'Google sign-in failed. Please try again.';
  }
}
