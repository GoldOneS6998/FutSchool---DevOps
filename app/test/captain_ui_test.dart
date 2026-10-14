import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/features/captain/domain/captain_repository.dart';
import 'package:futschool/features/captain/presentation/captain_forms.dart';
import 'package:futschool/features/captain/presentation/captain_design.dart';
import 'package:futschool/features/captain/presentation/captain_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'Profile initialization failure blocks private data and retry recovers',
    (tester) async {
      final repository = _FakeCaptainRepository()..initializationError = true;
      await _pump(tester, repository);
      expect(find.text('Hola, Carla'), findsNothing);
      expect(find.text('Halcones'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      repository.initializationError = false;
      await _tap(tester, find.text('Reintentar'));
      expect(repository.profileEnsured, 2);
      expect(find.text('Hola, Carla'), findsOneWidget);
      expect(find.text('Halcones'), findsOneWidget);
    },
  );

  testWidgets(
    'Home uses stored team, pending registrations and upcoming tournament',
    (tester) async {
      final repository = _FakeCaptainRepository();
      repository.registrations.value = [
        const TournamentRegistration(
          id: 'cup1_captain',
          tournamentId: 'cup1',
          captainUid: 'captain',
          teamName: 'Halcones',
          status: RegistrationStatus.pending,
        ),
      ];
      await _pump(tester, repository);
      expect(find.text('Hola, Carla'), findsOneWidget);
      expect(find.text('Halcones'), findsOneWidget);
      expect(find.text('Pendiente de revisión'), findsOneWidget);
      expect(find.text('Mi próximo partido'), findsOneWidget);
      expect(find.text('Copa universitaria'), findsNWidgets(2));
      expect(repository.profileEnsured, 1);
    },
  );

  testWidgets('Creating a team persists entered fields and returns to home', (
    tester,
  ) async {
    final repository = _FakeCaptainRepository();
    repository.team.value = null;
    await _pump(tester, repository);
    await _tap(tester, find.text('Registrar mi equipo'));
    await tester.enterText(
      find.byKey(const ValueKey('captain-team-name')),
      '  Jaguares  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('captain-team-description')),
      'Equipo de ingeniería',
    );
    await _tap(tester, find.byKey(const ValueKey('captain-save-team')));
    expect(repository.savedTeam?.name, 'Jaguares');
    expect(repository.savedTeam?.description, 'Equipo de ingeniería');
    expect(find.text('Jaguares'), findsOneWidget);
    expect(find.text('Gestionar mi equipo'), findsOneWidget);
  });

  testWidgets(
    'Player add, edit jersey and delete require actual persistence and confirmation',
    (tester) async {
      final repository = _FakeCaptainRepository();
      await _pump(tester, repository);
      await _tap(tester, find.byKey(const ValueKey('captain-nav-2')));
      await _tap(tester, find.text('Agregar jugador'));
      await tester.enterText(
        find.byKey(const ValueKey('captain-player-name')),
        'Ana Pérez',
      );
      await _tap(tester, find.byKey(const ValueKey('captain-player-position')));
      await _tap(tester, find.text('Defensa').last);
      await tester.enterText(
        find.byKey(const ValueKey('captain-player-number')),
        '4',
      );
      await _tap(tester, find.byKey(const ValueKey('captain-save-player')));
      expect(repository.players.value.single.name, 'Ana Pérez');
      expect(repository.players.value.single.position, PlayerPosition.defender);
      await _tap(tester, find.byTooltip('Editar Ana Pérez'));
      await tester.enterText(
        find.byKey(const ValueKey('captain-player-number')),
        '8',
      );
      await _tap(tester, find.byKey(const ValueKey('captain-save-player')));
      expect(repository.players.value.single.jerseyNumber, 8);
      await _tap(tester, find.text('Eliminar jugador').last);
      await _tap(tester, find.text('Cancelar'));
      expect(repository.players.value, hasLength(1));
      await _tap(tester, find.text('Eliminar jugador').last);
      await _tap(tester, find.text('Eliminar').last);
      expect(repository.players.value, isEmpty);
      expect(repository.deletedPlayer, '8');
    },
  );

  testWidgets(
    'Registration sends own team once while busy and displays pending server state',
    (tester) async {
      final repository = _FakeCaptainRepository();
      repository.registrationCompletion = Completer<void>();
      await _pump(tester, repository);
      await _tap(tester, find.text('Ver torneo'));
      await _tap(tester, find.text('Inscribir mi equipo / ver solicitud'));
      final button = find.byKey(const ValueKey('captain-register-tournament'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(repository.registrationCalls, 1);
      final filled = find.descendant(
        of: button,
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(filled).onPressed, isNull);
      repository.registrationCompletion!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Pendiente de revisión'), findsOneWidget);
      expect(find.text('Solicitud registrada'), findsOneWidget);
      expect(repository.registrations.value.single.captainUid, 'captain');
    },
  );

  testWidgets('Profile name is persisted while email remains read only', (
    tester,
  ) async {
    final repository = _FakeCaptainRepository();
    await _pump(tester, repository);
    await _tap(tester, find.byKey(const ValueKey('captain-nav-3')));
    expect(find.text('captain@example.test'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('captain-profile-name')),
      'Carla Méndez',
    );
    await _tap(tester, find.text('Guardar perfil'));
    expect(repository.profile.value!.displayName, 'Carla Méndez');
    expect(repository.profile.value!.email, 'captain@example.test');
    await _tap(tester, find.byKey(const ValueKey('captain-nav-0')));
    expect(find.text('Hola, Carla Méndez'), findsOneWidget);
  });

  testWidgets('Disabled profile blocks team and tournament operations', (
    tester,
  ) async {
    final repository = _FakeCaptainRepository();
    repository.profile.value = const CaptainProfile(
      id: 'captain',
      displayName: 'Carla',
      email: 'captain@example.test',
      disabled: true,
    );
    await _pump(tester, repository);
    expect(find.text('Acceso restringido'), findsOneWidget);
    expect(find.text('Registrar mi equipo'), findsNothing);
    expect(find.byKey(const ValueKey('captain-nav-1')), findsNothing);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets(
    'A failed collection read shows retry and does not masquerade as empty data',
    (tester) async {
      final repository = _FakeCaptainRepository();
      repository.tournamentError = true;
      await _pump(tester, repository);
      await _tap(tester, find.byKey(const ValueKey('captain-nav-1')));
      expect(
        find.text(
          'No se pudieron cargar o guardar los datos. Intenta de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.text('No hay torneos que coincidan.'), findsNothing);
      repository.tournamentError = false;
      await _tap(tester, find.text('Reintentar'));
      expect(find.text('Copa universitaria'), findsOneWidget);
    },
  );

  testWidgets(
    '320px viewport and large text retain navigation and team form without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakeCaptainRepository();
      await _pump(tester, repository, textScale: 2);
      await _tap(tester, find.byKey(const ValueKey('captain-nav-2')));
      await _tap(tester, find.text('Editar equipo'));
      await _tap(tester, find.text('Guardar equipo'));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Standings include finished games only and handle win, loss and draw',
    () {
      const teams = [
        AdminTeam(id: 'a', tournamentId: 'cup1', name: 'A'),
        AdminTeam(id: 'b', tournamentId: 'cup1', name: 'B'),
      ];
      final rows = captainStandings(teams, [
        _match('finished', AdminMatchStatus.finished, 3, 1),
        _match('draw', AdminMatchStatus.finished, 2, 2),
        _match('live', AdminMatchStatus.live, 9, 0),
        _match('cancelled', AdminMatchStatus.cancelled, 9, 0),
      ]);
      expect(rows.first.team.id, 'a');
      expect(rows.first.points, 4);
      expect(rows.first.played, 2);
      expect(rows.first.goalsFor, 5);
      expect(rows.first.goalsAgainst, 3);
      expect(rows.last.points, 1);
      expect(rows.last.lost, 1);
    },
  );

  test('Logo rejects unsupported content and oversized bytes before pixel decoding', () async {
    await expectLater(
      validatedCaptainLogo(Uint8List.fromList('<svg>script</svg>'.codeUnits)),
      throwsFormatException,
    );
    await expectLater(
      validatedCaptainLogo(Uint8List(51201)),
      throwsFormatException,
    );
    await expectLater(
      validatedCaptainLogo(
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0]),
      ),
      throwsFormatException,
    );
  });

  testWidgets('Logo accepts a bounded valid PNG generated by Flutter', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 2, 2),
        Paint()..color = Colors.green,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(2, 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final encoded = await validatedCaptainLogo(data!.buffer.asUint8List());
      expect(encoded, isNotEmpty);
      image.dispose();
      picture.dispose();
    });
  });

  testWidgets(
    'Ongoing tournament permits registration until the inclusive end date',
    (tester) async {
      final repository = _FakeCaptainRepository();
      repository.tournaments.value = [
        AdminTournament(
          id: 'cup1',
          name: 'Copa en curso',
          description: '',
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          endDate: DateTime.now().add(const Duration(days: 2)),
          maxTeams: 16,
          teamCount: 0,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: CaptainRegistrationPage(
            repository: repository,
            tournamentId: 'cup1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Enviar inscripción'));
      expect(repository.registrationCalls, 1);
      expect(find.text('Pendiente de revisión'), findsOneWidget);
    },
  );

  testWidgets(
    'Tournament search filters stored names and reports an empty search',
    (tester) async {
      final repository = _FakeCaptainRepository();
      await _pump(tester, repository);
      await _tap(tester, find.byKey(const ValueKey('captain-nav-1')));
      await tester.enterText(
        find.byKey(const ValueKey('captain-tournament-search')),
        'universitaria',
      );
      await tester.pumpAndSettle();
      expect(find.text('Copa universitaria'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('captain-tournament-search')),
        'sin-coincidencia',
      );
      await tester.pumpAndSettle();
      expect(find.text('No hay torneos que coincidan.'), findsOneWidget);
      expect(find.text('Copa universitaria'), findsNothing);
    },
  );

  testWidgets(
    'A stored compressed logo with oversized dimensions falls back before rendering',
    (tester) async {
      final bytes = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 1025, 1),
          Paint()..color = Colors.green,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(1025, 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final result = data!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        await expectLater(validatedCaptainLogo(result), throwsFormatException);
        return result;
      });
      expect(bytes!.length, lessThan(50 * 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptainTeamLogo(logoBase64: base64Encode(bytes)),
          ),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(
        tester.widget<CaptainAsset>(find.byType(CaptainAsset)).name,
        'shield',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  _FakeCaptainRepository repository, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: CaptainPage(repository: repository, onSignOut: () async {}),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

AdminMatch _match(String id, AdminMatchStatus status, int home, int away) =>
    AdminMatch(
      id: id,
      tournamentId: 'cup1',
      homeTeamId: 'a',
      awayTeamId: 'b',
      courtId: 'cancha_1',
      startsAt: DateTime(2026, 10, 15),
      status: status,
      homeScore: home,
      awayScore: away,
    );

class _Feed<T> {
  _Feed(this.value);
  T value;
  final _events = StreamController<T>.broadcast();
  Stream<T> watch() async* {
    yield value;
    yield* _events.stream;
  }

  void set(T next) {
    value = next;
    _events.add(next);
  }
}

class _FakeCaptainRepository implements CaptainRepository {
  final profile = _Feed<CaptainProfile?>(
    const CaptainProfile(
      id: 'captain',
      displayName: 'Carla',
      email: 'captain@example.test',
      disabled: false,
    ),
  );
  final team = _Feed<CaptainTeam?>(
    const CaptainTeam(
      id: 'captain',
      name: 'Halcones',
      description: 'Equipo universitario',
    ),
  );
  final players = _Feed<List<CaptainPlayer>>([]);
  final registrations = _Feed<List<TournamentRegistration>>([]);
  final tournaments = _Feed<List<AdminTournament>>([
    AdminTournament(
      id: 'cup1',
      name: 'Copa universitaria',
      description: 'Copa de la universidad',
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      maxTeams: 16,
      teamCount: 0,
    ),
  ]);
  int profileEnsured = 0;
  bool initializationError = false;
  int registrationCalls = 0;
  bool tournamentError = false;
  String? deletedPlayer;
  CaptainTeam? savedTeam;
  Completer<void>? registrationCompletion;

  @override
  Stream<CaptainProfile?> watchProfile() => profile.watch();
  @override
  Stream<CaptainTeam?> watchMyTeam() => team.watch();
  @override
  Stream<List<CaptainPlayer>> watchPlayers() => players.watch();
  @override
  Stream<List<AdminTournament>> watchTournaments() => tournamentError
      ? Stream.error(StateError('Internal connection diagnostic must not leak'))
      : tournaments.watch();
  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) =>
      Stream.value([]);
  @override
  Stream<List<AdminMatch>> watchMatches({String? tournamentId}) =>
      Stream.value([]);
  @override
  Stream<List<TournamentRegistration>> watchRegistrations() =>
      registrations.watch();
  @override
  Stream<AppSettings> watchSettings() => Stream.value(const AppSettings());
  @override
  Future<void> ensureProfile() async {
    profileEnsured++;
    if (initializationError) {
      throw const CaptainFailure(
        'Tu sesión inició, pero no se pudo preparar el perfil.',
      );
    }
  }

  @override
  Future<void> updateProfile({required String displayName}) async {
    profile.set(
      CaptainProfile(
        id: 'captain',
        displayName: displayName,
        email: profile.value!.email,
        disabled: false,
      ),
    );
  }

  @override
  Future<void> saveTeam({
    required String name,
    required String description,
    String? logoBase64,
  }) async {
    savedTeam = CaptainTeam(
      id: 'captain',
      name: name,
      description: description,
      logoBase64: logoBase64,
    );
    team.set(savedTeam);
  }

  @override
  Future<void> savePlayer({
    String? id,
    required String name,
    required PlayerPosition position,
    required int jerseyNumber,
  }) async {
    players.set([
      ...players.value.where((player) => player.id != id),
      CaptainPlayer(
        id: '$jerseyNumber',
        name: name,
        position: position,
        jerseyNumber: jerseyNumber,
      ),
    ]);
  }

  @override
  Future<void> deletePlayer(String id) async {
    deletedPlayer = id;
    players.set(players.value.where((player) => player.id != id).toList());
  }

  @override
  Future<void> registerForTournament(String tournamentId) async {
    registrationCalls++;
    if (registrationCompletion != null) await registrationCompletion!.future;
    registrations.set([
      TournamentRegistration(
        id: '${tournamentId}_captain',
        tournamentId: tournamentId,
        captainUid: 'captain',
        teamName: team.value!.name,
        status: RegistrationStatus.pending,
      ),
    ]);
  }
}
