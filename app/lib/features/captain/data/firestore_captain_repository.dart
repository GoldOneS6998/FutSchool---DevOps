import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/captain_repository.dart';
import '../domain/captain_validation.dart';
import 'firestore_models.dart';

class FirestoreCaptainRepository implements CaptainRepository {
  FirestoreCaptainRepository({required this.firestore, required this.auth});
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  Future<User> _authorize({bool requireProfile = true}) async {
    final initial = auth.currentUser;
    if (initial == null) {
      throw const CaptainFailure('Inicia sesión para continuar.');
    }
    await initial.reload();
    final user = auth.currentUser;
    if (user == null || user.uid != initial.uid || !user.emailVerified) {
      throw const CaptainFailure(
        'Verifica tu correo para acceder a tu equipo.',
      );
    }
    final token = await user.getIdTokenResult(true);
    if (token.claims?['email_verified'] != true) {
      throw const CaptainFailure('Verifica tu correo para continuar.');
    }
    if (requireProfile) {
      final profile = await firestore
          .collection('captainProfiles')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      if (!profile.exists) {
        throw const CaptainFailure('Completa tu perfil antes de continuar.');
      }
      if (profile.data()?['disabled'] != false) {
        throw const CaptainFailure(
          'Tu acceso está suspendido. Contacta al administrador.',
        );
      }
    }
    return user;
  }

  CaptainFailure _failure(FirebaseException error) =>
      CaptainFailure(switch (error.code) {
        'permission-denied' || 'unauthenticated' =>
          'No tienes permiso para esta operación. Actualiza tu sesión.',
        'unavailable' ||
        'network-request-failed' => 'No se pudo conectar. Revisa tu conexión.',
        'deadline-exceeded' ||
        'aborted' => 'El cambio no se confirmó. Actualiza e intenta de nuevo.',
        'resource-exhausted' =>
          'El servicio alcanzó su límite. Intenta más tarde.',
        _ => 'No se pudo completar la operación. Intenta de nuevo.',
      });
  Future<void> _write(
    Future<void> Function(User) action, {
    bool requireProfile = true,
    bool preparingProfile = false,
  }) async {
    try {
      await action(await _authorize(requireProfile: requireProfile));
    } on CaptainFailure {
      rethrow;
    } on FirebaseException catch (e) {
      if (preparingProfile && e.code == 'permission-denied') {
        throw const CaptainFailure(
          'Tu sesión inició correctamente, pero no tienes acceso al perfil. '
          'El administrador debe revisar los permisos de la aplicación.',
        );
      }
      throw _failure(e);
    } on TimeoutException {
      throw const CaptainFailure(
        'No se pudo conectar a tiempo. Comprueba tu conexión y reintenta.',
      );
    } catch (_) {
      throw CaptainFailure(
        preparingProfile
            ? 'Tu sesión inició, pero no se pudo preparar el perfil. '
                  'Reintenta; si continúa, contacta al administrador.'
            : 'No se pudo guardar el cambio. Intenta de nuevo.',
      );
    }
  }

  Stream<T> _document<T>(
    String collection,
    T Function(DocumentSnapshot<Map<String, dynamic>>) decode, {
    bool own = false,
    bool requireProfile = true,
  }) async* {
    try {
      final user = await _authorize(requireProfile: requireProfile);
      await for (final doc
          in firestore
              .collection(collection)
              .doc(own ? user.uid : 'general')
              .snapshots()) {
        yield decode(doc);
      }
    } on CaptainFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _failure(e);
    } catch (_) {
      throw const CaptainFailure(
        'No se pudieron consultar los datos. Actualiza e intenta de nuevo.',
      );
    }
  }

  Stream<List<T>> _list<T>(
    Query<Map<String, dynamic>> Function(String) query,
    T Function(DocumentSnapshot<Map<String, dynamic>>) decode,
    int Function(T, T) sort,
  ) async* {
    try {
      final user = await _authorize();
      await for (final snap in query(
        user.uid,
      ).limit(CaptainValidation.streamLimit).snapshots()) {
        final values = snap.docs.map(decode).toList()..sort(sort);
        yield List<T>.unmodifiable(values);
      }
    } on CaptainFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _failure(e);
    } catch (_) {
      throw const CaptainFailure(
        'No se pudieron consultar los datos. Actualiza e intenta de nuevo.',
      );
    }
  }

  @override
  Stream<CaptainProfile?> watchProfile() => _document(
    'captainProfiles',
    (d) => d.exists ? decodeProfile(d) : null,
    own: true,
    requireProfile: false,
  );
  @override
  Stream<CaptainTeam?> watchMyTeam() => _document(
    'captainTeams',
    (d) => d.exists ? decodeCaptainTeam(d) : null,
    own: true,
  );
  @override
  Stream<List<CaptainPlayer>> watchPlayers() => _list(
    (uid) =>
        firestore.collection('captainTeams').doc(uid).collection('players'),
    decodePlayer,
    (a, b) => a.jerseyNumber.compareTo(b.jerseyNumber),
  );
  @override
  Stream<List<AdminTournament>> watchTournaments() => _list(
    (_) => firestore.collection('adminTournaments'),
    decodeTournament,
    (a, b) => b.startDate.compareTo(a.startDate),
  );
  @override
  Stream<List<AdminTeam>> watchTeams({String? tournamentId}) {
    if (tournamentId != null) CaptainValidation.id(tournamentId);
    return _list(
      (_) => tournamentId == null
          ? firestore.collection('adminTeams')
          : firestore
                .collection('adminTeams')
                .where('tournamentId', isEqualTo: tournamentId),
      decodeEntrant,
      (a, b) => a.name.compareTo(b.name),
    );
  }

  @override
  Stream<List<AdminMatch>> watchMatches({String? tournamentId}) {
    if (tournamentId != null) CaptainValidation.id(tournamentId);
    return _list(
      (_) => tournamentId == null
          ? firestore.collection('adminMatches')
          : firestore
                .collection('adminMatches')
                .where('tournamentId', isEqualTo: tournamentId),
      decodeMatch,
      (a, b) => a.startsAt.compareTo(b.startsAt),
    );
  }

  @override
  Stream<List<TournamentRegistration>> watchRegistrations() => _list(
    (uid) => firestore
        .collection('tournamentRegistrations')
        .where('captainUid', isEqualTo: uid),
    decodeRegistration,
    (a, b) => a.tournamentId.compareTo(b.tournamentId),
  );
  @override
  Stream<AppSettings> watchSettings() =>
      _document('appSettings', decodeSettings);

  @override
  Future<void> ensureProfile() => _write(
    (user) async {
      final ref = firestore.collection('captainProfiles').doc(user.uid);
      // Check server access before a transaction. Existing profiles need no write;
      // permission and connection failures retain their typed Firebase errors.
      final existing = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (existing.exists) return;
      if (user.email == null || user.email!.trim().isEmpty) {
        throw const CaptainFailure(
          'Esta cuenta necesita un correo verificado para crear el perfil.',
        );
      }
      await firestore.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (doc.exists) return;
        final suggested = user.displayName?.trim() ?? '';
        final name =
            suggested.length >= 2 &&
                suggested.length <= 100 &&
                !suggested.contains('\n') &&
                !suggested.contains('\r')
            ? suggested
            : 'Capitán';
        tx.set(ref, {
          'displayName': name,
          'email': user.email!,
          'disabled': false,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    },
    requireProfile: false,
    preparingProfile: true,
  );
  @override
  Future<void> updateProfile({required String displayName}) =>
      _write((user) async {
        CaptainValidation.name(displayName, max: 100);
        await firestore.collection('captainProfiles').doc(user.uid).update({
          'displayName': displayName.trim(),
          'email': user.email!,
          'updatedBy': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
  @override
  Future<void> saveTeam({
    required String name,
    required String description,
    String? logoBase64,
  }) => _write((user) async {
    CaptainValidation.team(
      name: name,
      description: description,
      logoBase64: logoBase64,
    );
    final ref = firestore.collection('captainTeams').doc(user.uid);
    await firestore.runTransaction((tx) async {
      final previous = await tx.get(ref);
      final data = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'logoBase64': logoBase64,
        'updatedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (previous.exists) {
        tx.update(ref, data);
      } else {
        tx.set(ref, {
          ...data,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  });
  @override
  Future<void> savePlayer({
    String? id,
    required String name,
    required PlayerPosition position,
    required int jerseyNumber,
  }) => _write((user) async {
    CaptainValidation.player(name: name, jerseyNumber: jerseyNumber);
    if (id != null) CaptainValidation.id(id);
    final targetId = jerseyNumber.toString();
    final players = firestore
        .collection('captainTeams')
        .doc(user.uid)
        .collection('players');
    final target = players.doc(targetId);
    await firestore.runTransaction((tx) async {
      final team = await tx.get(
        firestore.collection('captainTeams').doc(user.uid),
      );
      final targetDoc = await tx.get(target);
      final old = id != null && id != targetId
          ? await tx.get(players.doc(id))
          : null;
      if (!team.exists) {
        throw const CaptainFailure(
          'Crea tu equipo antes de agregar jugadores.',
        );
      }
      if (targetDoc.exists && id != targetId) {
        throw const CaptainFailure('Ese número de camiseta ya está ocupado.');
      }
      if (id != null &&
          (id == targetId ? !targetDoc.exists : old?.exists != true)) {
        throw const CaptainFailure('El jugador ya no está disponible.');
      }
      final data = <String, dynamic>{
        'name': name.trim(),
        'position': position.name,
        'jerseyNumber': jerseyNumber,
        'updatedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (id == targetId) {
        tx.update(target, data);
      } else {
        tx.set(target, {
          ...data,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (id != null) tx.delete(players.doc(id));
      }
    });
  });
  @override
  Future<void> deletePlayer(String id) => _write((user) async {
    CaptainValidation.id(id);
    await firestore
        .collection('captainTeams')
        .doc(user.uid)
        .collection('players')
        .doc(id)
        .delete();
  });
  @override
  Future<void> registerForTournament(String tournamentId) =>
      _write((user) async {
        CaptainValidation.id(tournamentId);
        final id = '${tournamentId}__${user.uid}';
        CaptainValidation.id(id);
        final registration = firestore
            .collection('tournamentRegistrations')
            .doc(id);
        await firestore.runTransaction((tx) async {
          final previous = await tx.get(registration);
          final team = await tx.get(
            firestore.collection('captainTeams').doc(user.uid),
          );
          final tournament = await tx.get(
            firestore.collection('adminTournaments').doc(tournamentId),
          );
          final settings = await tx.get(
            firestore.collection('appSettings').doc('general'),
          );
          if (previous.exists) {
            throw const CaptainFailure(
              'Tu equipo ya tiene una solicitud para este torneo.',
            );
          }
          if (!team.exists) {
            throw const CaptainFailure('Crea tu equipo antes de inscribirlo.');
          }
          if (!tournament.exists) {
            throw const CaptainFailure('El torneo ya no está disponible.');
          }
          final cup = decodeTournament(tournament);
          if (cup.teamCount >= cup.maxTeams) {
            throw const CaptainFailure('El torneo alcanzó su cupo.');
          }
          if (DateTime.now().toUtc().isAfter(
            cup.endDate.add(const Duration(days: 1)),
          )) {
            throw const CaptainFailure('El torneo ya terminó.');
          }
          if (!decodeSettings(settings).registrationEnabled) {
            throw const CaptainFailure('Las inscripciones están cerradas.');
          }
          tx.set(registration, {
            'tournamentId': tournamentId,
            'captainUid': user.uid,
            'teamName': team.data()!['name'],
            'status': 'pending',
            'entrantId': null,
            'reviewNote': '',
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
      });
}
