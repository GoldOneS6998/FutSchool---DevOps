enum AdminMatchStatus { scheduled, live, finished, cancelled }

class AdminTournament {
  const AdminTournament({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.maxTeams,
    required this.teamCount,
  });

  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int maxTeams;
  final int teamCount;
}

class AdminTeam {
  const AdminTeam({
    required this.id,
    required this.tournamentId,
    required this.name,
  });

  final String id;
  final String tournamentId;
  final String name;
}

class AdminMatch {
  const AdminMatch({
    required this.id,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.courtId,
    required this.startsAt,
    required this.status,
    this.homeScore,
    this.awayScore,
  });

  final String id;
  final String tournamentId;
  final String homeTeamId;
  final String awayTeamId;
  final String courtId;
  final DateTime startsAt;
  final AdminMatchStatus status;
  final int? homeScore;
  final int? awayScore;
}

class AdminFailure implements Exception {
  const AdminFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
