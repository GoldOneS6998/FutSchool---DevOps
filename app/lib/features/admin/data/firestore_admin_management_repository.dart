import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../captain/data/firestore_models.dart';
import '../../captain/domain/captain_validation.dart';
import '../domain/admin_management_repository.dart';
import '../domain/admin_validation.dart';

class FirestoreAdminManagementRepository implements AdminManagementRepository {
  FirestoreAdminManagementRepository({
    required this.firestore,
    required this.auth,
  });
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  Future<String> _authorize() async {
    final initial = auth.currentUser;
    if (initial == null) {
      throw const AdminFailure('Inicia sesión con una cuenta administradora.');
    }
    await initial.reload();
    final user = auth.currentUser;
    if (user == null || user.uid != initial.uid || !user.emailVerified) {
      throw const AdminFailure(
        'Se requiere una cuenta verificada de administrador.',
      );
    }
    final token = await user.getIdTokenResult(true);
    if (token.claims?['admin'] != true ||
        token.claims?['email_verified'] != true) {
      throw const AdminFailure('Tu cuenta no tiene permiso de administración.');
    }
    return user.uid;
  }

  AdminFailure _failure(FirebaseException error) =>
      AdminFailure(switch (error.code) {
        'permission-denied' ||
        'unauthenticated' => 'No tienes permiso para esta operación.',
        'unavailable' ||
        'network-request-failed' => 'No se pudo conectar. Revisa tu conexión.',
        'deadline-exceeded' ||
        'aborted' => 'No se confirmó el cambio. Actualiza e intenta de nuevo.',
        'resource-exhausted' =>
          'El servicio alcanzó su límite. Intenta más tarde.',
        _ => 'No se pudo completar la operación. Intenta de nuevo.',
      });
  Future<void> _write(Future<void> Function(String) action) async {
    try {
      await action(await _authorize());
    } on AdminFailure {
      rethrow;
    } on CaptainFailure catch (e) {
      throw AdminFailure(e.message);
    } on FirebaseException catch (e) {
      throw _failure(e);
    } catch (_) {
      throw const AdminFailure(
        'No se pudo guardar el cambio. Intenta de nuevo.',
      );
    }
  }

  Stream<List<T>> _list<T>(
    Query<Map<String, dynamic>> query,
    T Function(DocumentSnapshot<Map<String, dynamic>>) decode,
    int Function(T, T) sort,
  ) async* {
    try {
      await _authorize();
      await for (final snap in query.limit(200).snapshots()) {
        final values = snap.docs.map(decode).toList()..sort(sort);
        yield List<T>.unmodifiable(values);
      }
    } on AdminFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _failure(e);
    } catch (_) {
      throw const AdminFailure(
        'No se pudieron consultar los datos. Actualiza e intenta de nuevo.',
      );
    }
  }

  @override
  Stream<List<CaptainProfile>> watchCaptains() => _list(
    firestore.collection('captainProfiles'),
    decodeProfile,
    (a, b) => a.displayName.compareTo(b.displayName),
  );
  @override
  Stream<List<CaptainTeam>> watchCaptainTeams() => _list(
    firestore.collection('captainTeams'),
    decodeCaptainTeam,
    (a, b) => a.name.compareTo(b.name),
  );
  @override
  Stream<List<CaptainPlayer>> watchPlayers(String captainUid) {
    AdminValidation.id(captainUid);
    return _list(
      firestore
          .collection('captainTeams')
          .doc(captainUid)
          .collection('players'),
      decodePlayer,
      (a, b) => a.jerseyNumber.compareTo(b.jerseyNumber),
    );
  }

  @override
  Stream<List<TournamentRegistration>> watchRegistrations() => _list(
    firestore.collection('tournamentRegistrations'),
    decodeRegistration,
    (a, b) => a.teamName.compareTo(b.teamName),
  );
  @override
  Stream<AppSettings> watchSettings() async* {
    try {
      await _authorize();
      await for (final doc
          in firestore.collection('appSettings').doc('general').snapshots()) {
        yield decodeSettings(doc);
      }
    } on AdminFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _failure(e);
    } catch (_) {
      throw const AdminFailure('No se pudo consultar la configuración.');
    }
  }

  @override
  Future<void> setCaptainDisabled({
    required String uid,
    required bool disabled,
  }) => _write((adminUid) async {
    AdminValidation.id(uid);
    await firestore.collection('captainProfiles').doc(uid).update({
      'disabled': disabled,
      'updatedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
  @override
  Future<void> reviewRegistration({
    required String id,
    required bool approve,
    String note = '',
  }) => _write((uid) async {
    AdminValidation.id(id);
    if (note.trim().length > 500) {
      throw const AdminFailure('La observación permite hasta 500 caracteres.');
    }
    final registrationRef = firestore
        .collection('tournamentRegistrations')
        .doc(id);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(registrationRef);
      if (!snap.exists) {
        throw const AdminFailure('La solicitud ya no está disponible.');
      }
      final registration = decodeRegistration(snap);
      if (registration.status != RegistrationStatus.pending) {
        throw const AdminFailure('Esta solicitud ya fue revisada.');
      }
      if (!approve) {
        tx.update(registrationRef, {
          'status': 'rejected',
          'entrantId': null,
          'reviewNote': note.trim(),
          'reviewedBy': uid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      final tournamentRef = firestore
          .collection('adminTournaments')
          .doc(registration.tournamentId);
      final entrantRef = firestore.collection('adminTeams').doc(id);
      final tournamentDoc = await tx.get(tournamentRef);
      final captain = await tx.get(
        firestore.collection('captainProfiles').doc(registration.captainUid),
      );
      final entrant = await tx.get(entrantRef);
      if (!tournamentDoc.exists) {
        throw const AdminFailure('El torneo ya no está disponible.');
      }
      if (!captain.exists || captain.data()?['disabled'] != false) {
        throw const AdminFailure(
          'El capitán está suspendido o su perfil ya no está disponible.',
        );
      }
      final tournament = decodeTournament(tournamentDoc);
      if (tournament.teamCount >= tournament.maxTeams) {
        throw const AdminFailure('El torneo ya alcanzó su cupo.');
      }
      if (entrant.exists) {
        throw const AdminFailure(
          'El equipo ya está registrado en este torneo.',
        );
      }
      tx.set(entrantRef, {
        'name': registration.teamName,
        'tournamentId': registration.tournamentId,
        'captainUid': registration.captainUid,
        'registrationId': id,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(tournamentRef, {
        'teamCount': tournament.teamCount + 1,
        'lastTeamId': id,
      });
      tx.update(registrationRef, {
        'status': 'approved',
        'entrantId': id,
        'reviewNote': note.trim(),
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  });
  @override
  Future<void> updateTournamentMetadata({
    required String id,
    required String name,
    required String description,
    required int maxTeams,
  }) => _write((uid) async {
    AdminValidation.id(id);
    final ref = firestore.collection('adminTournaments').doc(id);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw const AdminFailure('El torneo ya no está disponible.');
      }
      final tournament = decodeTournament(snap);
      AdminValidation.tournament(
        name: name,
        description: description,
        startDate: tournament.startDate,
        endDate: tournament.endDate,
        maxTeams: maxTeams,
      );
      if (maxTeams < tournament.teamCount) {
        throw const AdminFailure(
          'El cupo no puede ser menor que los equipos inscritos.',
        );
      }
      tx.update(ref, {
        'name': name.trim(),
        'description': description.trim(),
        'maxTeams': maxTeams,
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  });
  @override
  Future<void> saveSettings(AppSettings settings) => _write((uid) async {
    CaptainValidation.settings(settings);
    final privacy = {
      'privacyResponsible': settings.privacyResponsible.trim(),
      'privacyContact': settings.privacyContact.trim(),
      'privacyNotice': settings.privacyNotice.trim(),
      'privacyVersion': settings.privacyVersion.trim(),
    };
    final batch = firestore.batch();
    batch.set(firestore.collection('appSettings').doc('general'), {
      'registrationEnabled': settings.registrationEnabled,
      'announcement': settings.announcement.trim(),
      ...privacy,
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(firestore.collection('publicPrivacy').doc('notice'), privacy);
    await batch.commit();
  });
}
