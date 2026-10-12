import 'admin_models.dart';

export 'admin_models.dart';

abstract class AdminRepository {
  Stream<List<AdminTournament>> watchTournaments();
  Stream<List<AdminTeam>> watchTeams({String? tournamentId});
  Stream<List<AdminMatch>> watchMatches({String? tournamentId});

  Future<void> createTournament({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int maxTeams,
  });

  Future<void> createTeam({required String tournamentId, required String name});

  Future<void> createMatch({
    required String tournamentId,
    required String homeTeamId,
    required String awayTeamId,
    required String courtId,
    required DateTime startsAt,
  });

  Future<void> updateMatchResult({
    required String id,
    required AdminMatchStatus status,
    int? homeScore,
    int? awayScore,
  });
}
