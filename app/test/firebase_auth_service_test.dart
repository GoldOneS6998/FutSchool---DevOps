import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/features/auth/data/firebase_auth_service.dart';
import 'package:futschool/features/auth/domain/auth_service.dart';

class _User extends Fake implements User {
  bool failProfile = false;
  bool failVerification = false;
  int verificationCalls = 0;
  @override
  Future<void> updateDisplayName(String? value) async {
    if (failProfile) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    verificationCalls++;
    if (failVerification) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.account);
  final _User account;
  @override
  User get user => account;
}

class _Auth extends Fake implements FirebaseAuth {
  final account = _User();
  int signOutCalls = 0;
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => _Credential(account);
  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  test(
    'Registro correcto envía verificación y cierra la sesión temporal',
    () async {
      final auth = _Auth();
      await FirebaseAuthService(auth)
          .signUp('Alumno', 'alumno@example.com', 'Test-password!');
      expect(auth.account.verificationCalls, 1);
      expect(auth.signOutCalls, 1);
    },
  );
  test(
    'Fallo de verificación tras crear cuenta cierra sesión y explica estado',
    () async {
      final auth = _Auth();
      auth.account.failVerification = true;
      await expectLater(
        FirebaseAuthService(auth)
            .signUp('Alumno', 'alumno@example.com', 'Test-password!'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            contains('La cuenta se creó'),
          ),
        ),
      );
      expect(auth.signOutCalls, 1);
    },
  );
  test(
    'Fallo de perfil tras crear cuenta no conserva la sesión temporal',
    () async {
      final auth = _Auth();
      auth.account.failProfile = true;
      await expectLater(
        FirebaseAuthService(auth)
            .signUp('Alumno', 'alumno@example.com', 'Test-password!'),
        throwsA(isA<AuthFailure>()),
      );
      expect(auth.account.verificationCalls, 0);
      expect(auth.signOutCalls, 1);
    },
  );
}
