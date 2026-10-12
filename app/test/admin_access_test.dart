import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/app/app.dart';
import 'package:futschool/features/auth/domain/auth_service.dart';
import 'package:futschool/features/auth/domain/admin_access.dart';
import 'package:futschool/features/admin/domain/admin_repository.dart';
import 'package:futschool/features/admin/presentation/admin_page.dart';

class _Auth implements AuthService, AdminAccess {
  final sessions = StreamController<bool>.broadcast();
  final roles = StreamController<bool>.broadcast();
  @override
  Stream<bool> get sessionChanges => sessions.stream;
  @override
  Stream<bool> get adminChanges => roles.stream;
  @override
  Future<void> refreshAdminAccess() async {}
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signUp(String name, String email, String password) async {}
  @override
  Future<void> signOut() async => sessions.add(false);
}

class _Repository implements AdminRepository {
  int queries = 0;
  @override
  Stream<List<AdminTournament>> watchTournaments() {
    queries++;
    return Stream.value([]);
  }

  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) {
    queries++;
    return Stream.value([]);
  }

  @override
  Stream<List<AdminMatch>> watchMatches({String? tournamentId}) {
    queries++;
    return Stream.value([]);
  }

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

void main() {
  late _Auth auth;
  late _Repository repository;
  setUp(() {
    auth = _Auth();
    repository = _Repository();
  });
  tearDown(() async {
    await auth.sessions.close();
    await auth.roles.close();
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      FutSchoolApp(auth: auth, adminRepository: repository),
    );
    auth.sessions.add(true);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Usuario sin rol no abre administrador ni consulta datos', (
    tester,
  ) async {
    await open(tester);
    auth.roles.add(false);
    await tester.pumpAndSettle();
    expect(find.byType(AdminPage), findsNothing);
    expect(repository.queries, 0);
    expect(find.text('Torneos escolares'), findsOneWidget);
  });
  testWidgets('Rol revocado elimina las rutas administrativas abiertas', (
    tester,
  ) async {
    await open(tester);
    auth.roles.add(true);
    await tester.pumpAndSettle();
    expect(find.byType(AdminPage), findsOneWidget);
    final context = tester.element(find.byType(AdminPage));
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: Text('Ruta administrativa privada')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ruta administrativa privada'), findsOneWidget);
    auth.roles.add(false);
    await tester.pumpAndSettle();
    expect(find.text('Ruta administrativa privada'), findsNothing);
    expect(find.byType(AdminPage), findsNothing);
    expect(find.text('Torneos escolares'), findsOneWidget);
  });
  testWidgets('Fallo al comprobar rol cierra el acceso', (tester) async {
    await open(tester);
    auth.roles.addError(Exception('sin conexión'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminPage), findsNothing);
    expect(repository.queries, 0);
    expect(find.text('No se pudieron verificar los permisos.'), findsOneWidget);
  });
}
