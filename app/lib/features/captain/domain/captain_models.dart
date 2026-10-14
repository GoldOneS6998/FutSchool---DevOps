enum PlayerPosition { goalkeeper, defender, midfielder, forward }

enum RegistrationStatus { pending, approved, rejected }

class CaptainProfile {
  const CaptainProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.disabled,
  });
  final String id;
  final String displayName;
  final String email;
  final bool disabled;
}

class CaptainTeam {
  const CaptainTeam({
    required this.id,
    required this.name,
    required this.description,
    this.logoBase64,
  });
  final String id;
  final String name;
  final String description;
  final String? logoBase64;
}

class CaptainPlayer {
  const CaptainPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.jerseyNumber,
  });
  final String id;
  final String name;
  final PlayerPosition position;
  final int jerseyNumber;
}

class TournamentRegistration {
  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.captainUid,
    required this.teamName,
    required this.status,
    this.entrantId,
    this.reviewNote = '',
  });
  final String id;
  final String tournamentId;
  final String captainUid;
  final String teamName;
  final RegistrationStatus status;
  final String? entrantId;
  final String reviewNote;
}

class AppSettings {
  const AppSettings({
    this.registrationEnabled = true,
    this.announcement = '',
    this.privacyResponsible = '',
    this.privacyContact = '',
    this.privacyNotice = '',
    this.privacyVersion = '',
  });
  final bool registrationEnabled;
  final String announcement;
  final String privacyResponsible;
  final String privacyContact;
  final String privacyNotice;
  final String privacyVersion;
}

class CaptainFailure implements Exception {
  const CaptainFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
