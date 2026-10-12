import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/app/app.dart';
import 'package:futschool/features/auth/domain/auth_service.dart';

class TestAuth implements AuthService {
  final sessions = StreamController<bool>();
  int passwordCalls = 0;
  int googleCalls = 0;
  int signUpCalls = 0;
  bool fail = false;

  @override
  Stream<bool> get sessionChanges => sessions.stream;
  @override
  Future<void> signIn(String email, String password) async {
    passwordCalls++;
    if (fail) throw const AuthFailure('Correo o contraseña incorrectos.');
    sessions.add(true);
  }

  @override
  Future<void> signUp(String fullName, String email, String password) async {
    signUpCalls++;
    if (fail) throw const AuthFailure('Este correo ya está registrado.');
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    sessions.add(true);
  }

  @override
  Future<void> signOut() async => sessions.add(false);
}

void main() {
  late TestAuth auth;
  setUp(() => auth = TestAuth());
  tearDown(() => auth.sessions.close());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(FutSchoolApp(auth: auth));
    auth.sessions.add(false);
    await tester.pumpAndSettle();
  }

  testWidgets('Valida campos sin enviar credenciales vacías', (tester) async {
    await open(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Introduce tu correo.'), findsOneWidget);
    expect(find.text('Introduce tu contraseña.'), findsOneWidget);
    expect(auth.passwordCalls, 0);
  });

  testWidgets('Muestra el error de credenciales y permite reintentar', (
    tester,
  ) async {
    auth.fail = true;
    await open(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'alumno@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'incorrecta');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(auth.passwordCalls, 1);
    auth.fail = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Torneos escolares'), findsOneWidget);
  });

  testWidgets('Google abre la sesión y cerrar sesión devuelve al login', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.text('Continuar con Google'));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(auth.googleCalls, 1);
    expect(find.text('Torneos escolares'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('Navega a la pantalla de crear cuenta y se registra', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.text('Regístrate aquí'));
    await tester.tap(find.text('Regístrate aquí'));
    await tester.pumpAndSettle();

    expect(find.text('Regístrate para continuar'), findsOneWidget);
    expect(find.text('FUTSCHOOL ACADEMY'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Juan Pérez');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'juan@ejemplo.edu',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.enterText(find.byType(TextFormField).at(3), '123456');

    final button = find.widgetWithText(ElevatedButton, 'Crear Cuenta');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(auth.signUpCalls, 1);
    expect(
      find.text(
        'Cuenta creada con éxito. Te enviamos un correo de verificación. Revisa tu bandeja de entrada e inicia sesión.',
      ),
      findsOneWidget,
    );
  });
}
