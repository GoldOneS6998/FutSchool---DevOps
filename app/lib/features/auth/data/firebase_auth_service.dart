import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;
  Future<void>? _googleInitialization;

  @override
  Stream<bool> get sessionChanges =>
      _auth.authStateChanges().map((user) => user != null);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Correo o contraseña incorrectos.',
        'invalid-email' => 'Introduce un correo válido.',
        'user-disabled' => 'Esta cuenta está deshabilitada.',
        'network-request-failed' => 'Revisa tu conexión e intenta de nuevo.',
        'too-many-requests' => 'Demasiados intentos. Intenta más tarde.',
        'account-exists-with-different-credential' =>
          'Inicia sesión con el método original de tu cuenta.',
        'popup-closed-by-user' ||
        'cancelled-popup-request' => 'Se canceló el inicio de sesión.',
        _ => 'No se pudo iniciar sesión. Intenta de nuevo.',
      });
    } on GoogleSignInException catch (error) {
      throw AuthFailure(
        error.code == GoogleSignInExceptionCode.canceled
            ? 'Se canceló el inicio de sesión.'
            : 'No se pudo conectar con Google. Intenta de nuevo.',
      );
    }
  }

  @override
  Future<void> signIn(String email, String password) => _run(() async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  });

  @override
  Future<void> signInWithGoogle() => _run(() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw const AuthFailure('Google no pudo verificar tu cuenta.');
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  });

  @override
  Future<void> signOut() => _auth.signOut();
}
