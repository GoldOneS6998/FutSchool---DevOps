import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/features/auth/domain/auth_service.dart';
import 'package:futschool/features/auth/presentation/register_page.dart';

class TestAuth implements AuthService {
  final sessions = StreamController<bool>();
  int signUpCalls = 0;
  bool fail = false;

  @override
  Stream<bool> get sessionChanges => sessions.stream;

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signUp(String fullName, String email, String password) async {
    signUpCalls++;
    if (fail) throw const AuthFailure('Este correo ya está registrado.');
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async => sessions.add(false);
}

void main() {
  late TestAuth auth;

  setUp(() {
    auth = TestAuth();
  });

  tearDown(() {
    auth.sessions.close();
  });

  testWidgets(
    'La pantalla de registro se adapta a una pantalla pequeña y escala de texto',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: RegisterPage(auth: auth)));

      expect(find.text('FutSchool'), findsOneWidget);
      expect(find.text('Regístrate para continuar'), findsOneWidget);
      expect(find.text('FUTSCHOOL ACADEMY'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Comprueba que el contenido no desborde al ampliar el texto del sistema.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(home: RegisterPage(auth: auth)),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Valida formulario de registro y completa el flujo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RegisterPage(auth: auth)),
      ),
    );

    // Intenta enviar campos vacíos
    final submitBtn = find.widgetWithText(ElevatedButton, 'Crear Cuenta');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Introduce tu nombre completo.'), findsOneWidget);
    expect(find.text('Introduce tu correo.'), findsOneWidget);
    expect(auth.signUpCalls, 0);

    // Llena los campos correctamente
    await tester.enterText(find.byType(TextFormField).at(0), 'María Belén');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'belen@ejemplo.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.enterText(find.byType(TextFormField).at(3), '123456');

    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(auth.signUpCalls, 1);
  });
}
