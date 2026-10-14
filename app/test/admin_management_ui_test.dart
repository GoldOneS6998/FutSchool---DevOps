import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/features/admin/domain/admin_management_repository.dart';
import 'package:futschool/features/admin/domain/admin_repository.dart';
import 'package:futschool/features/admin/presentation/admin_page.dart';

class _AdminData implements AdminRepository {
  @override
  Stream<List<AdminTournament>> watchTournaments() => Stream.value([
    AdminTournament(
      id: 'cup',
      name: 'Copa universitaria',
      description: '',
      startDate: DateTime.utc(2026),
      endDate: DateTime.utc(2027),
      maxTeams: 16,
      teamCount: 2,
    ),
  ]);
  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) =>
      Stream.value([]);
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
  }) async {}
  @override
  Future<void> createTeam({
    required String tournamentId,
    required String name,
  }) async {}
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

class _ManagementData implements AdminManagementRepository {
  String? disabledUid;
  bool? disabled;
  String? rosterUid;
  String? registrationId;
  bool? registrationApproval;
  String? reviewNote;
  AppSettings? savedSettings;
  Completer<void>? pendingSettings;
  bool failSettings = false;
  int settingsWrites = 0;
  bool failReviews = false;
  int tournamentUpdates = 0;
  String? updatedTournamentName;
  final registrations =
      StreamController<List<TournamentRegistration>>.broadcast();

  List<TournamentRegistration> get seedRegistrations => const [
    TournamentRegistration(
      id: 'request',
      tournamentId: 'cup',
      captainUid: 'captain-a',
      teamName: 'Lobos',
      status: RegistrationStatus.pending,
    ),
  ];

  @override
  Stream<List<CaptainProfile>> watchCaptains() => Stream.value(const [
    CaptainProfile(
      id: 'captain-a',
      displayName: 'Capitán A',
      email: 'a@example.test',
      disabled: false,
    ),
    CaptainProfile(
      id: 'captain-b',
      displayName: 'Capitán B',
      email: 'b@example.test',
      disabled: true,
    ),
  ]);
  @override
  Stream<List<CaptainTeam>> watchCaptainTeams() => Stream.value(const [
    CaptainTeam(
      id: 'captain-a',
      name: 'Lobos',
      description: 'Equipo universitario',
    ),
  ]);
  @override
  Stream<List<CaptainPlayer>> watchPlayers(String captainUid) {
    rosterUid = captainUid;
    return Stream.value(const [
      CaptainPlayer(
        id: 'player',
        name: 'Jugador de prueba',
        position: PlayerPosition.defender,
        jerseyNumber: 4,
      ),
    ]);
  }

  @override
  Stream<List<TournamentRegistration>> watchRegistrations() async* {
    yield seedRegistrations;
    yield* registrations.stream;
  }

  @override
  Stream<AppSettings> watchSettings() => Stream.value(const AppSettings());
  @override
  Future<void> setCaptainDisabled({
    required String uid,
    required bool disabled,
  }) async {
    disabledUid = uid;
    this.disabled = disabled;
  }

  @override
  Future<void> reviewRegistration({
    required String id,
    required bool approve,
    String note = '',
  }) async {
    registrationId = id;
    registrationApproval = approve;
    reviewNote = note;
    if (failReviews) {
      throw const AdminFailure('La inscripción no se pudo revisar.');
    }
  }

  @override
  Future<void> updateTournamentMetadata({
    required String id,
    required String name,
    required String description,
    required int maxTeams,
  }) async {
    tournamentUpdates++;
    updatedTournamentName = name;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    settingsWrites++;
    if (failSettings) {
      throw const AdminFailure('No se pudo guardar la configuración.');
    }
    await pendingSettings?.future;
    savedSettings = settings;
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder.hitTestable(),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, _ManagementData repository) async {
  addTearDown(repository.registrations.close);
  await tester.pumpWidget(
    MaterialApp(
      home: AdminPage(
        repository: _AdminData(),
        managementRepository: repository,
        onSignOut: () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _panel(WidgetTester tester) => _tap(
  tester,
  find.byKey(const ValueKey('adminAction:Panel de Administración')),
);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('Inicio muestra solicitudes reales y actualiza el contador', (
    tester,
  ) async {
    final repository = _ManagementData();
    await _open(tester, repository);
    await tester.scrollUntilVisible(
      find.byKey(const Key('pendingRegistrationsCount')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 solicitudes esperando confirmación.'), findsOneWidget);
    repository.registrations.add([]);
    await tester.pumpAndSettle();
    expect(find.text('0 solicitudes esperando confirmación.'), findsOneWidget);
  });

  testWidgets(
    'Cancelar suspensión no cambia acceso y confirmar usa UID seleccionado',
    (tester) async {
      final repository = _ManagementData();
      await _open(tester, repository);
      await _panel(tester);
      await _tap(
        tester,
        find.byKey(const ValueKey('adminAction:Gestionar usuarios')),
      );
      await _tap(tester, find.byKey(const ValueKey('captainAccess:captain-a')));
      await _tap(tester, find.text('Cancelar'));
      expect(repository.disabledUid, isNull);
      await _tap(tester, find.byKey(const ValueKey('captainAccess:captain-a')));
      await _tap(tester, find.text('Confirmar'));
      expect(repository.disabledUid, 'captain-a');
      expect(repository.disabled, isTrue);
      expect(find.text('Acceso suspendido.'), findsOneWidget);
    },
  );

  testWidgets('Buscar un usuario acota la lista sin mostrar otras cuentas', (
    tester,
  ) async {
    final repository = _ManagementData();
    await _open(tester, repository);
    await _panel(tester);
    await _tap(
      tester,
      find.byKey(const ValueKey('adminAction:Gestionar usuarios')),
    );
    await tester.enterText(
      find.byKey(const Key('adminUsersSearch')),
      'b@example.test',
    );
    await tester.pumpAndSettle();
    expect(find.text('Capitán A'), findsNothing);
    expect(find.text('Capitán B'), findsOneWidget);
  });

  testWidgets('Consultar integrantes usa el capitán dueño del equipo', (
    tester,
  ) async {
    final repository = _ManagementData();
    await _open(tester, repository);
    await _panel(tester);
    await _tap(
      tester,
      find.byKey(const ValueKey('adminAction:Gestionar equipos')),
    );
    await _tap(tester, find.byKey(const ValueKey('adminRoster:captain-a')));
    expect(repository.rosterUid, 'captain-a');
    expect(find.text('Jugador de prueba'), findsOneWidget);
    expect(find.text('Defensa'), findsOneWidget);
  });

  testWidgets(
    'Aprobar inscripción envía identificador y comentario al servidor',
    (tester) async {
      final repository = _ManagementData();
      await _open(tester, repository);
      await _panel(tester);
      await _tap(
        tester,
        find.byKey(const ValueKey('adminAction:Gestionar torneos')),
      );
      await _tap(tester, find.text('Editar e inscripciones'));
      await _tap(
        tester,
        find.byKey(const ValueKey('approveRegistration:request')),
      );
      await tester.enterText(
        find.byKey(const Key('registrationReviewNote')),
        'Documentación revisada',
      );
      await _tap(tester, find.text('Confirmar'));
      expect(repository.registrationId, 'request');
      expect(repository.registrationApproval, isTrue);
      expect(repository.reviewNote, 'Documentación revisada');
    },
  );

  testWidgets('Fallo de configuración conserva el aviso para reintentar', (
    tester,
  ) async {
    final repository = _ManagementData()..failSettings = true;
    await _open(tester, repository);
    await _panel(tester);
    await _tap(
      tester,
      find.byKey(const ValueKey('adminAction:Configuración general')),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('privacyContact')))
          .controller!
          .text,
      'ernex9897@gmail.com',
    );
    await tester.enterText(
      find.byKey(const Key('settingsAnnouncement')),
      'Inscripciones abiertas',
    );
    await _tap(tester, find.byKey(const Key('saveSettings')));
    expect(find.text('No se pudo guardar la configuración.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('settingsAnnouncement')))
          .controller!
          .text,
      'Inscripciones abiertas',
    );
    repository.failSettings = false;
    await _tap(tester, find.byKey(const Key('saveSettings')));
    expect(repository.savedSettings!.announcement, 'Inscripciones abiertas');
  });

  testWidgets(
    'Rechazar conserva el comentario tras un fallo y permite reintentar',
    (tester) async {
      final repository = _ManagementData()..failReviews = true;
      await _open(tester, repository);
      await _panel(tester);
      await _tap(
        tester,
        find.byKey(const ValueKey('adminAction:Gestionar torneos')),
      );
      await _tap(tester, find.text('Editar e inscripciones'));
      final reject = find.byKey(const ValueKey('rejectRegistration:request'));
      await _tap(tester, reject);
      await tester.enterText(
        find.byKey(const Key('registrationReviewNote')),
        'Completar integrantes',
      );
      await _tap(tester, find.text('Confirmar'));
      expect(find.text('La inscripción no se pudo revisar.'), findsOneWidget);
      await _tap(tester, reject);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('registrationReviewNote')))
            .controller!
            .text,
        'Completar integrantes',
      );
      repository.failReviews = false;
      await _tap(tester, find.text('Confirmar'));
      expect(repository.registrationApproval, isFalse);
      expect(repository.reviewNote, 'Completar integrantes');
      expect(find.text('Inscripción rechazada.'), findsOneWidget);
    },
  );

  testWidgets('Cupo inferior a equipos existentes no guarda el torneo', (
    tester,
  ) async {
    final repository = _ManagementData();
    await _open(tester, repository);
    await _panel(tester);
    await _tap(
      tester,
      find.byKey(const ValueKey('adminAction:Gestionar torneos')),
    );
    await _tap(tester, find.text('Editar e inscripciones'));
    await tester.enterText(
      find.byKey(const Key('editTournamentCapacity')),
      '1',
    );
    await _tap(tester, find.byKey(const Key('editTournamentSubmit')));
    expect(repository.tournamentUpdates, 0);
    expect(
      find.text('El cupo debe estar entre 2 y 64 equipos.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('editTournamentCapacity')),
      '16',
    );
    await tester.enterText(
      find.byKey(const Key('editTournamentName')),
      'Copa actualizada',
    );
    await _tap(tester, find.byKey(const Key('editTournamentSubmit')));
    expect(repository.tournamentUpdates, 1);
    expect(repository.updatedTournamentName, 'Copa actualizada');
  });

  testWidgets(
    'Configuración bloquea guardar dos veces mientras espera respuesta',
    (tester) async {
      final repository = _ManagementData()..pendingSettings = Completer<void>();
      await _open(tester, repository);
      await _panel(tester);
      await _tap(
        tester,
        find.byKey(const ValueKey('adminAction:Configuración general')),
      );
      final submit = find.byKey(const Key('saveSettings'));
      await tester.scrollUntilVisible(
        submit,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      expect(repository.settingsWrites, 1);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      repository.pendingSettings!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Configuración guardada.'), findsOneWidget);
    },
  );
}
