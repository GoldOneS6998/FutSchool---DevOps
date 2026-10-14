import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/captain_repository.dart';

CaptainProfile decodeProfile(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return CaptainProfile(
    id: doc.id,
    displayName: d['displayName'] as String,
    email: d['email'] as String,
    disabled: d['disabled'] as bool,
  );
}

CaptainTeam decodeCaptainTeam(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return CaptainTeam(
    id: doc.id,
    name: d['name'] as String,
    description: d['description'] as String,
    logoBase64: d['logoBase64'] as String?,
  );
}

CaptainPlayer decodePlayer(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return CaptainPlayer(
    id: doc.id,
    name: d['name'] as String,
    position: PlayerPosition.values.byName(d['position'] as String),
    jerseyNumber: d['jerseyNumber'] as int,
  );
}

TournamentRegistration decodeRegistration(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final d = doc.data()!;
  return TournamentRegistration(
    id: doc.id,
    tournamentId: d['tournamentId'] as String,
    captainUid: d['captainUid'] as String,
    teamName: d['teamName'] as String,
    status: RegistrationStatus.values.byName(d['status'] as String),
    entrantId: d['entrantId'] as String?,
    reviewNote: d['reviewNote'] as String,
  );
}

AppSettings decodeSettings(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data();
  if (d == null) return const AppSettings();
  return AppSettings(
    registrationEnabled: d['registrationEnabled'] as bool,
    announcement: d['announcement'] as String,
    privacyResponsible: d['privacyResponsible'] as String,
    privacyContact: d['privacyContact'] as String,
    privacyNotice: d['privacyNotice'] as String,
    privacyVersion: d['privacyVersion'] as String,
  );
}

AdminTournament decodeTournament(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return AdminTournament(
    id: doc.id,
    name: d['name'] as String,
    description: d['description'] as String,
    startDate: (d['startDate'] as Timestamp).toDate().toUtc(),
    endDate: (d['endDate'] as Timestamp).toDate().toUtc(),
    maxTeams: d['maxTeams'] as int,
    teamCount: d['teamCount'] as int,
  );
}

AdminTeam decodeEntrant(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return AdminTeam(
    id: doc.id,
    tournamentId: d['tournamentId'] as String,
    name: d['name'] as String,
  );
}

AdminMatch decodeMatch(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return AdminMatch(
    id: doc.id,
    tournamentId: d['tournamentId'] as String,
    homeTeamId: d['homeTeamId'] as String,
    awayTeamId: d['awayTeamId'] as String,
    courtId: d['courtId'] as String,
    startsAt: (d['startsAt'] as Timestamp).toDate().toUtc(),
    status: AdminMatchStatus.values.byName(d['status'] as String),
    homeScore: d['homeScore'] as int?,
    awayScore: d['awayScore'] as int?,
  );
}
