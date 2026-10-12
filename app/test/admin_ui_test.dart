import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/features/admin/domain/admin_repository.dart';
import 'package:futschool/features/admin/presentation/admin_page.dart';

class _Repository implements AdminRepository {
  int tournamentCreates = 0;
  int teamCreates = 0;
  bool failTeam = false;
  Completer<void>? pendingTournament;

  @override
  Stream<List<AdminTournament>> watchTournaments() => Stream.value([
    AdminTournament(
      id: 't1',
      name: 'Copa escolar',
      description: '',
      startDate: DateTime(2026, 1, 1).toUtc(),
      endDate: DateTime(2028, 12, 31).toUtc(),
      maxTeams: 16,
      teamCount: 2,
    ),
  ]);

  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) => Stream.value([
    const AdminTeam(id: 'home', tournamentId: 't1', name: 'Lobos'),
    const AdminTeam(id: 'away', tournamentId: 't1', name: 'Tigres'),
  ]);

  @override
  Stream<List<AdminMatch>> watchMatches({String? tournamentId}) =>
      Stream.value([]);

  @override
  Future<void> createTournament({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int maxTeams,
  }) async {
    tournamentCreates++;
    await pendingTournament?.future;
  }

  @override
  Future<void> createTeam({
    required String tournamentId,
    required String name,
  }) async {
    teamCreates++;
    if (failTeam) throw const AdminFailure('No se pudo guardar el equipo.');
  }

  @override
  Future<void> createMatch({
    required String tournamentId,
    required String homeTeamId,
    required String awayTeamId,
    required String courtId,
    required DateTime startsAt,
  }) async {}

  @override
  Future<void> updateMatchResult({
    required String id,
    required AdminMatchStatus status,
    int? homeScore,
    int? awayScore,
  }) async {}
}

Future<void> _open(
  WidgetTester tester,
  _Repository repository, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: AdminPage(repository: repository, onSignOut: () async {}),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final matches = find.text(text);
  if (matches.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      matches,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await _tapFinder(tester, matches.last);
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder.hitTestable(),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('Dashboard cabe en 320px con texto al 200 por ciento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(tester, _Repository(), textScale: 2);
    expect(find.text('Hola, Admin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tapFinder(
      tester,
      find.byKey(const ValueKey('adminAction:Crear torneo')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('tournamentName')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('tournamentName')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Torneo vacío no envía operación al repositorio', (tester) async {
    final repository = _Repository();
    await _open(tester, repository);
    await _tapFinder(
      tester,
      find.byKey(const ValueKey('adminAction:Crear torneo')),
    );
    await _tapFinder(tester, find.byKey(const Key('createTournamentSubmit')));
    expect(repository.tournamentCreates, 0);
    expect(find.text('Introduce entre 3 y 100 caracteres.'), findsOneWidget);
    expect(find.text('Selecciona la fecha.'), findsNWidgets(2));
  });

  testWidgets('Error al registrar equipo conserva los datos para reintentar', (
    tester,
  ) async {
    final repository = _Repository()..failTeam = true;
    await _open(tester, repository);
    await _tapFinder(
      tester,
      find.byKey(const ValueKey('adminAction:Panel de Administración')),
    );
    await _tapFinder(
      tester,
      find.byKey(const ValueKey('adminAction:Gestionar equipos')),
    );
    await _tapFinder(tester, find.byKey(const Key('registerTeamOpen')));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Copa escolar');
    await tester.enterText(find.byKey(const Key('teamName')), 'Nuevos Lobos');
    await _tapFinder(tester, find.byKey(const Key('createTeamSubmit')));
    expect(repository.teamCreates, 1);
    expect(find.text('No se pudo guardar el equipo.'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('teamName')),
    );
    expect(nameField.controller!.text, 'Nuevos Lobos');
    repository.failTeam = false;
    await _tapFinder(tester, find.byKey(const Key('createTeamSubmit')));
    expect(repository.teamCreates, 2);
    expect(find.text('Equipo registrado.'), findsOneWidget);
  });

  testWidgets('El formulario bloquea envío duplicado mientras guarda', (
    tester,
  ) async {
    final repository = _Repository()..pendingTournament = Completer<void>();
    await _open(tester, repository);
    await _tapFinder(
      tester,
      find.byKey(const ValueKey('adminAction:Crear torneo')),
    );
    await tester.enterText(
      find.byKey(const Key('tournamentName')),
      'Copa de prueba',
    );
    await tester.enterText(find.byKey(const Key('tournamentCapacity')), '16');
    await _tapText(tester, 'Seleccionar fecha');
    await _tapText(tester, 'Aceptar');
    await _tapText(tester, 'Seleccionar fecha');
    await _tapText(tester, 'Aceptar');
    final submit = find.widgetWithText(FilledButton, 'Crear torneo');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(repository.tournamentCreates, 1);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    repository.pendingTournament!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Torneo creado.'), findsOneWidget);
  });
}
