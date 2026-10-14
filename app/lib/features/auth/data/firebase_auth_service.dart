import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_service.dart';
import '../domain/admin_access.dart';
import '../domain/account_access.dart';

class FirebaseAuthService
    implements AuthService, AdminAccess, AccountAccess, SessionIdentityAccess {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;
  Future<void>? _googleInitialization;

  @override
  Stream<bool> get sessionChanges =>
      _auth.authStateChanges().map((user) => user != null);

  @override
  Stream<String?> get identityChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Stream<bool> get adminChanges =>
      _auth.idTokenChanges().asyncMap((user) async {
        if (user == null || !user.emailVerified) return false;
        final token = await user.getIdTokenResult();
        return token.claims?['admin'] == true &&
            token.claims?['email_verified'] == true;
      });

  @override
  Future<void> refreshAdminAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AuthFailure('Inicia sesión de nuevo.');
      await user.reload();
      await _auth.currentUser?.getIdTokenResult(true);
    } on FirebaseAuthException {
      throw const AuthFailure('No se pudieron comprobar los permisos.');
    }
  }

  @override
  Stream<bool> get verifiedChanges =>
      _auth.idTokenChanges().asyncMap((user) async {
        if (user == null || !user.emailVerified) return false;
        final token = await user.getIdTokenResult();
        return token.claims?['email_verified'] == true;
      });

  @override
  Future<void> refreshVerification() => refreshAdminAccess();

  @override
  Future<void> sendVerification() => _run(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Inicia sesión de nuevo.');
    await user.sendEmailVerification();
  });

  @override
  Future<void> resetPassword(String email) async {
    final normalized = email.trim();
    if (normalized.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      throw const AuthFailure('Introduce un correo válido.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: normalized);
    } on FirebaseAuthException catch (error) {
      // Preserve an identical confirmation for absent accounts.
      if (error.code == 'user-not-found') return;
      throw AuthFailure(switch (error.code) {
        'too-many-requests' => 'Demasiados intentos. Intenta más tarde.',
        'network-request-failed' => 'Revisa tu conexión e intenta de nuevo.',
        _ => 'No se pudo solicitar la recuperación. Intenta de nuevo.',
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Correo o contraseña incorrectos.',
        'email-already-in-use' => 'Este correo ya está registrado.',
        'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
        'invalid-email' => 'Introduce un correo válido.',
        'user-disabled' => 'Esta cuenta está deshabilitada.',
        'network-request-failed' => 'Revisa tu conexión e intenta de nuevo.',
        'too-many-requests' => 'Demasiados intentos. Intenta más tarde.',
        'account-exists-with-different-credential' =>
          'Inicia sesión con el método original de tu cuenta.',
        'popup-closed-by-user' ||
        'cancelled-popup-request' => 'Se canceló el inicio de sesión.',
        'unauthorized-domain' =>
          'Este dominio no está autorizado para iniciar sesión.',
        'popup-blocked' => 'Permite la ventana de Google e intenta de nuevo.',
        'operation-not-allowed' => 'Este método de acceso no está habilitado.',
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
  Future<void> signUp(String fullName, String email, String password) =>
      _run(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        try {
          if (fullName.trim().isNotEmpty) {
            await credential.user?.updateDisplayName(fullName.trim());
          }
          await credential.user?.sendEmailVerification();
        } on FirebaseAuthException {
          throw const AuthFailure(
            'La cuenta se creó, pero no se completó la verificación. '
            'Inicia sesión con esa cuenta; evita volver a registrarla.',
          );
        } finally {
          await _auth.signOut();
        }
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
