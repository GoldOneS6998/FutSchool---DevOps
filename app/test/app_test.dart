import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/app/app.dart';

void main() {
  testWidgets('La aplicación inicia y se adapta a una pantalla pequeña', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FutSchoolApp());

    expect(find.text('FutSchool'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Comprueba que el contenido no desborde al ampliar el texto del sistema.
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: FutSchoolApp(),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
