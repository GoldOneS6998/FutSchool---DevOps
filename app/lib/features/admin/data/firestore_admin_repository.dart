import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/admin_repository.dart';
import '../domain/admin_validation.dart';

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository({required this.firestore, required this.auth});

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      firestore.collection('adminTournaments');
  CollectionReference<Map<String, dynamic>> get _teams =>
      firestore.collection('adminTeams');
  CollectionReference<Map<String, dynamic>> get _matches =>
      firestore.collection('adminMatches');
  CollectionReference<Map<String, dynamic>> get _reservations =>
      firestore.collection('adminReservations');

  /// This is an additional usability check. Deployed rules are authoritative.
  Future<String> _authorize() async {
    final user = auth.currentUser;
    if (user == null) {
      throw const AdminFailure('Inicia sesión con una cuenta administradora.');
    }
    await user.reload();
    final current = auth.currentUser;
    if (current == null || current.uid != user.uid || !current.emailVerified) {
      throw const AdminFailure(
        'Se requiere una cuenta verificada de administrador.',
      );
    }
    final token = await current.getIdTokenResult(true);
    if (token.claims?['admin'] != true ||
        token.claims?['email_verified'] != true) {
      throw const AdminFailure('Tu cuenta no tiene permiso de administración.');
    }
    return current.uid;
  }

  Future<void> _write(Future<void> Function(String uid) action) async {
    try {
      await action(await _authorize());
    } on AdminFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw _firebaseFailure(error);
    } catch (_) {
      throw const AdminFailure(
        'No se pudo guardar el cambio. Intenta de nuevo.',
      );
    }
  }

  AdminFailure _firebaseFailure(FirebaseException error) =>
      AdminFailure(switch (error.code) {
        'permission-denied' ||
        'unauthenticated' => 'No tienes permiso para esta operación.',
        'unavailable' ||
        'network-request-failed' => 'No se pudo conectar. Revisa tu conexión.',
        'deadline-exceeded' || 'aborted' =>
          'No se confirmó el cambio. Actualiza los datos e intenta de nuevo.',
        'resource-exhausted' =>
          'El servicio alcanzó su límite. Intenta más tarde.',
        _ => 'No se pudo completar la operación. Intenta de nuevo.',
      });

  Stream<List<T>> _watch<T>(
    Query<Map<String, dynamic>> query,
    T Function(DocumentSnapshot<Map<String, dynamic>>) decode,
    int Function(T, T) compare,
  ) async* {
    try {
      await _authorize();
      await for (final snapshot
          in query.limit(AdminValidation.streamLimit).snapshots()) {
        final values = snapshot.docs.map(decode).toList()..sort(compare);
        yield List<T>.unmodifiable(values);
      }
    } on AdminFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw _firebaseFailure(error);
    } catch (_) {
      throw const AdminFailure(
        'No se pudieron consultar los datos. Intenta de nuevo.',
      );
    }
  }

  @override
  Stream<List<AdminTournament>> watchTournaments() => _watch(
    _tournaments,
    _tournament,
    (a, b) => b.startDate.compareTo(a.startDate),
  );

  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) {
    if (tournamentId != null) AdminValidation.id(tournamentId);
    return _watch(
      tournamentId == null
          ? _teams
          : _teams.where('tournamentId', isEqualTo: tournamentId),
      _team,
      (a, b) => a.name.compareTo(b.name),
    );
  }

  @override
  Stream<List<AdminMatch>> watchMatches({String? tournamentId}) {
    if (tournamentId != null) AdminValidation.id(tournamentId);
    return _watch(
      tournamentId == null
          ? _matches
          : _matches.where('tournamentId', isEqualTo: tournamentId),
      _match,
      (a, b) => a.startsAt.compareTo(b.startsAt),
    );
  }

  @override
  Future<void> createTournament({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int maxTeams,
  }) => _write((uid) async {
    AdminValidation.tournament(
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      maxTeams: maxTeams,
    );
    await _tournaments.doc().set({
      'name': name.trim(),
      'description': description.trim(),
      'startDate': Timestamp.fromDate(AdminValidation.calendarDate(startDate)),
      'endDate': Timestamp.fromDate(AdminValidation.calendarDate(endDate)),
      'maxTeams': maxTeams,
      'teamCount': 0,
      'lastTeamId': null,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> createTeam({
    required String tournamentId,
    required String name,
  }) => _write((uid) async {
    AdminValidation.team(tournamentId: tournamentId, name: name);
    final tournamentRef = _tournaments.doc(tournamentId);
    final teamRef = _teams.doc();
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tournamentRef);
      if (!snapshot.exists) {
        throw const AdminFailure('El torneo ya no está disponible.');
      }
      final tournament = _tournament(snapshot);
      if (tournament.teamCount >= tournament.maxTeams) {
        throw const AdminFailure('El torneo ya alcanzó su cupo de equipos.');
      }
      transaction.set(teamRef, {
        'tournamentId': tournamentId,
        'name': name.trim(),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(tournamentRef, {
        'teamCount': tournament.teamCount + 1,
        'lastTeamId': teamRef.id,
      });
    });
  });

  @override
  Future<void> createMatch({
    required String tournamentId,
    required String homeTeamId,
    required String awayTeamId,
    required String courtId,
    required DateTime startsAt,
  }) => _write((uid) async {
    final start = startsAt.toUtc();
    AdminValidation.match(
      tournamentId: tournamentId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      courtId: courtId,
      startsAt: start,
    );
    final matchRef = _matches.doc();
    final reservationRefs = [
      _reservations.doc('court_${courtId}_${start.millisecondsSinceEpoch}'),
      _reservations.doc('team_${homeTeamId}_${start.millisecondsSinceEpoch}'),
      _reservations.doc('team_${awayTeamId}_${start.millisecondsSinceEpoch}'),
    ];
    await firestore.runTransaction((transaction) async {
      final tournamentSnapshot = await transaction.get(
        _tournaments.doc(tournamentId),
      );
      final homeSnapshot = await transaction.get(_teams.doc(homeTeamId));
      final awaySnapshot = await transaction.get(_teams.doc(awayTeamId));
      final reservations = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final reference in reservationRefs) {
        reservations.add(await transaction.get(reference));
      }
      if (!tournamentSnapshot.exists ||
          !homeSnapshot.exists ||
          !awaySnapshot.exists) {
        throw const AdminFailure(
          'El torneo o alguno de los equipos ya no está disponible.',
        );
      }
      final tournament = _tournament(tournamentSnapshot);
      final home = _team(homeSnapshot);
      final away = _team(awaySnapshot);
      if (home.tournamentId != tournamentId ||
          away.tournamentId != tournamentId) {
        throw const AdminFailure(
          'Ambos equipos deben pertenecer al torneo seleccionado.',
        );
      }
      AdminValidation.matchInTournament(start, tournament);
      if (reservations.any((reservation) => reservation.exists)) {
        throw const AdminFailure(
          'La cancha o alguno de los equipos tiene otro partido en esa hora.',
        );
      }
      transaction.set(matchRef, {
        'tournamentId': tournamentId,
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'courtId': courtId,
        'startsAt': Timestamp.fromDate(start),
        'status': AdminMatchStatus.scheduled.name,
        'homeScore': null,
        'awayScore': null,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final reference in reservationRefs) {
        transaction.set(reference, {
          'matchId': matchRef.id,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  });

  @override
  Future<void> updateMatchResult({
    required String id,
    required AdminMatchStatus status,
    int? homeScore,
    int? awayScore,
  }) => _write((uid) async {
    AdminValidation.id(id);
    AdminValidation.result(
      status: status,
      homeScore: homeScore,
      awayScore: awayScore,
    );
    final matchRef = _matches.doc(id);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) {
        throw const AdminFailure('El partido ya no está disponible.');
      }
      AdminValidation.transition(_match(snapshot).status, status);
      transaction.update(matchRef, {
        'status': status.name,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  });

  AdminTournament _tournament(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw const AdminFailure('El torneo no está disponible.');
    try {
      final result = AdminTournament(
        id: snapshot.id,
        name: data['name'] as String,
        description: data['description'] as String,
        startDate: (data['startDate'] as Timestamp).toDate().toUtc(),
        endDate: (data['endDate'] as Timestamp).toDate().toUtc(),
        maxTeams: data['maxTeams'] as int,
        teamCount: data['teamCount'] as int,
      );
      AdminValidation.tournament(
        name: result.name,
        description: result.description,
        startDate: result.startDate,
        endDate: result.endDate,
        maxTeams: result.maxTeams,
      );
      if (result.teamCount < 0 || result.teamCount > result.maxTeams) {
        throw const FormatException();
      }
      return result;
    } catch (_) {
      throw const AdminFailure(
        'Un torneo tiene datos inválidos. Revisa su configuración.',
      );
    }
  }

  AdminTeam _team(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw const AdminFailure('El equipo no está disponible.');
    try {
      final result = AdminTeam(
        id: snapshot.id,
        tournamentId: data['tournamentId'] as String,
        name: data['name'] as String,
      );
      AdminValidation.team(
        tournamentId: result.tournamentId,
        name: result.name,
      );
      return result;
    } catch (_) {
      throw const AdminFailure(
        'Un equipo tiene datos inválidos. Revisa su configuración.',
      );
    }
  }

  AdminMatch _match(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw const AdminFailure('El partido no está disponible.');
    }
    try {
      final result = AdminMatch(
        id: snapshot.id,
        tournamentId: data['tournamentId'] as String,
        homeTeamId: data['homeTeamId'] as String,
        awayTeamId: data['awayTeamId'] as String,
        courtId: data['courtId'] as String,
        startsAt: (data['startsAt'] as Timestamp).toDate().toUtc(),
        status: AdminMatchStatus.values.byName(data['status'] as String),
        homeScore: data['homeScore'] as int?,
        awayScore: data['awayScore'] as int?,
      );
      AdminValidation.match(
        tournamentId: result.tournamentId,
        homeTeamId: result.homeTeamId,
        awayTeamId: result.awayTeamId,
        courtId: result.courtId,
        startsAt: result.startsAt,
      );
      AdminValidation.result(
        status: result.status,
        homeScore: result.homeScore,
        awayScore: result.awayScore,
      );
      return result;
    } catch (_) {
      throw const AdminFailure(
        'Un partido tiene datos inválidos. Revisa su configuración.',
      );
    }
  }
}
