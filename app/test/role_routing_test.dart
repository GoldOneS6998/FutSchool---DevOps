import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futschool/app/app.dart';
import 'package:futschool/features/auth/domain/auth_service.dart';
import 'package:futschool/features/auth/domain/admin_access.dart';
import 'package:futschool/features/auth/domain/account_access.dart';
import 'package:futschool/features/admin/domain/admin_repository.dart';
import 'package:futschool/features/admin/presentation/admin_page.dart';
import 'package:futschool/features/captain/domain/captain_repository.dart';
import 'package:futschool/features/captain/presentation/captain_page.dart';

class _Auth implements AuthService, AdminAccess {
  final sessions = StreamController<bool>();
  final roles = StreamController<bool>.broadcast();
  @override
  Stream<bool> get sessionChanges => sessions.stream;
  @override
  Stream<bool> get adminChanges => roles.stream;
  @override
  Future<void> signIn(String e, String p) async {}
  @override
  Future<void> signUp(String n, String e, String p) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signOut() async {
    sessions.add(false);
  }

  @override
  Future<void> refreshAdminAccess() async {}
}

class _Admin extends Fake implements AdminRepository {
  @override
  Stream<List<AdminTournament>> watchTournaments() => Stream.value([]);
  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) =>
      Stream.value([]);
  @override
  Stream<List<AdminMatch>> watchMatches({String? tournamentId}) =>
      Stream.value([]);
}

class _IdentityAuth extends _Auth implements SessionIdentityAccess {
  final identities = StreamController<String?>.broadcast();
  @override
  Stream<String?> get identityChanges => identities.stream;
}

class _Captain extends Fake implements CaptainRepository {
  int initialized = 0;
  @override
  Future<void> ensureProfile() async {
    initialized++;
  }

  @override
  Stream<CaptainProfile?> watchProfile() => Stream.value(
    const CaptainProfile(
      id: 'qa',
      displayName: 'Prueba',
      email: 'qa@example.test',
      disabled: false,
    ),
  );
  @override
  Stream<CaptainTeam?> watchMyTeam() => Stream.value(null);
  @override
  Stream<List<CaptainPlayer>> watchPlayers() => Stream.value([]);
  @override
  Stream<List<AdminTournament>> watchTournaments() => Stream.value([]);
  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) =>
      Stream.value([]);
  @override
  Stream<List<AdminMatch>> watchMatches({String? tournamentId}) =>
      Stream.value([]);
  @override
  Stream<List<TournamentRegistration>> watchRegistrations() => Stream.value([]);
  @override
  Stream<AppSettings> watchSettings() => Stream.value(const AppSettings());
}

void main() {
  late _Auth auth;
  late _Captain captain;
  setUp(() {
    auth = _Auth();
    captain = _Captain();
  });
  tearDown(() async {
    await auth.sessions.close();
    await auth.roles.close();
  });
  Future<void> open(WidgetTester tester, bool admin) async {
    await tester.pumpWidget(
      FutSchoolApp(
        auth: auth,
        adminRepository: _Admin(),
        captainRepository: captain,
      ),
    );
    auth.sessions.add(true);
    await tester.pump();
    await tester.pump();
    if (auth case final _IdentityAuth identity) {
      identity.identities.add('account-a');
      await tester.pump();
      await tester.pump();
    }
    auth.roles.add(admin);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Shared login routes captain and changes role discard private open routes',
    (tester) async {
      await open(tester, false);
      expect(find.byType(CaptainPage), findsOneWidget);
      expect(find.byType(AdminPage), findsNothing);
      expect(captain.initialized, 1);
      unawaited(
        Navigator.of(tester.element(find.byType(CaptainPage))).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Text('Formulario del capitán abierto')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Formulario del capitán abierto'), findsOneWidget);
      auth.roles.add(true);
      await tester.pumpAndSettle();
      expect(find.byType(AdminPage), findsOneWidget);
      expect(find.text('Formulario del capitán abierto'), findsNothing);
      auth.roles.add(false);
      await tester.pumpAndSettle();
      expect(find.byType(CaptainPage), findsOneWidget);
      expect(find.byType(AdminPage), findsNothing);
    },
  );
  testWidgets(
    'Signing out discards captain routes and returns to shared login',
    (tester) async {
      await open(tester, false);
      unawaited(
        Navigator.of(tester.element(find.byType(CaptainPage))).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Text('Datos del capitán abiertos')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Datos del capitán abiertos'), findsNothing);
      expect(find.byType(CaptainPage), findsNothing);
      expect(find.text('Continuar con Google'), findsOneWidget);
    },
  );
  testWidgets(
    'Direct UID change with same role clears old forms and reinitializes profile',
    (tester) async {
      final identity = _IdentityAuth();
      auth = identity;
      addTearDown(identity.identities.close);
      await open(tester, false);
      expect(captain.initialized, 1);
      unawaited(
        Navigator.of(tester.element(find.byType(CaptainPage))).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Text('Datos privados de cuenta A')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      identity.identities.add('account-b');
      await tester.pump();
      await tester.pump();
      expect(find.text('Datos privados de cuenta A'), findsNothing);
      identity.roles.add(false);
      await tester.pumpAndSettle();
      expect(find.byType(CaptainPage), findsOneWidget);
      expect(captain.initialized, 2);
    },
  );
}
