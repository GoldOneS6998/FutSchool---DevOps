import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/app/app.dart';
import 'package:futschool/features/auth/domain/account_access.dart';
import 'package:futschool/features/auth/domain/auth_service.dart';
import 'package:futschool/features/auth/presentation/recovery_page.dart';
import 'package:futschool/features/privacy/domain/privacy_repository.dart';
import 'package:futschool/features/privacy/presentation/privacy_page.dart';

class _Account implements AuthService, AccountAccess {
  final sessions = StreamController<bool>.broadcast();
  final verified = StreamController<bool>.broadcast();
  int resets = 0;
  int verificationEmails = 0;
  int refreshes = 0;
  bool fail = false;
  @override
  Stream<bool> get sessionChanges => sessions.stream;
  @override
  Stream<bool> get verifiedChanges => verified.stream;
  @override
  Future<void> signIn(String e, String p) async {}
  @override
  Future<void> signUp(String n, String e, String p) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signOut() async => sessions.add(false);
  @override
  Future<void> refreshVerification() async {
    refreshes++;
    verified.add(true);
  }

  @override
  Future<void> sendVerification() async {
    verificationEmails++;
  }

  @override
  Future<void> resetPassword(String email) async {
    resets++;
    if (fail) throw const AuthFailure('Revisa tu conexión e intenta de nuevo.');
  }
}

class _Privacy implements PrivacyRepository {
  bool fail = false;
  int reads = 0;
  @override
  Future<PrivacyNotice> readNotice() async {
    reads++;
    if (fail) throw StateError('internal details must never be shown');
    return const PrivacyNotice();
  }
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  late _Account account;
  setUp(() => account = _Account());
  tearDown(() async {
    await account.sessions.close();
    await account.verified.close();
  });
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Unverified session stays outside team screens and can refresh or sign out',
    (tester) async {
      await tester.pumpWidget(FutSchoolApp(auth: account));
      account.sessions.add(true);
      await tester.pump();
      await tester.pump();
      account.verified.add(false);
      await tester.pumpAndSettle();
      expect(find.text('Verifica tu correo'), findsOneWidget);
      expect(find.text('Torneos escolares'), findsNothing);
      await tap(tester, find.text('Reenviar verificación'));
      expect(account.verificationEmails, 1);
      await tap(tester, find.text('Ya verifiqué mi correo'));
      expect(account.refreshes, 1);
      expect(find.text('Torneos escolares'), findsOneWidget);
    },
  );
  testWidgets('Verification lookup error fails closed', (tester) async {
    await tester.pumpWidget(FutSchoolApp(auth: account));
    account.sessions.add(true);
    await tester.pump();
    await tester.pump();
    account.verified.addError(StateError('network'));
    await tester.pumpAndSettle();
    expect(find.text('Verifica tu correo'), findsOneWidget);
    expect(find.text('Torneos escolares'), findsNothing);
  });
  testWidgets(
    'Password recovery rejects empty mail and gives generic confirmation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RecoveryPage(account: account)),
      );
      await tap(tester, find.text('Enviar instrucciones'));
      expect(account.resets, 0);
      expect(find.text('Introduce un correo válido.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'synthetic@example.test',
      );
      await tap(tester, find.text('Enviar instrucciones'));
      expect(account.resets, 1);
      expect(
        find.textContaining('Si el correo corresponde a una cuenta'),
        findsOneWidget,
      );
    },
  );
  testWidgets('Password recovery preserves input after connection failure', (
    tester,
  ) async {
    account.fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: RecoveryPage(account: account, email: 'synthetic@example.test'),
      ),
    );
    await tap(tester, find.text('Enviar instrucciones'));
    expect(find.text('Revisa tu conexión e intenta de nuevo.'), findsOneWidget);
    expect(find.text('synthetic@example.test'), findsOneWidget);
    account.fail = false;
    await tap(tester, find.text('Enviar instrucciones'));
    expect(account.resets, 2);
    expect(
      find.textContaining('Si el correo corresponde a una cuenta'),
      findsOneWidget,
    );
  });
  testWidgets(
    'Privacy error reveals no internals, retries and identifies incomplete notice',
    (tester) async {
      final repository = _Privacy()..fail = true;
      await tester.pumpWidget(
        MaterialApp(home: PrivacyPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo consultar el aviso de privacidad.'),
        findsOneWidget,
      );
      expect(find.textContaining('internal details'), findsNothing);
      repository.fail = false;
      await tap(tester, find.text('Reintentar'));
      expect(repository.reads, 2);
      expect(find.textContaining('todavía no ha completado'), findsOneWidget);
    },
  );
}
