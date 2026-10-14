import '../../admin/domain/admin_models.dart';
import 'captain_models.dart';
export '../../admin/domain/admin_models.dart';
export 'captain_models.dart';

abstract class CaptainRepository {
  Stream<CaptainProfile?> watchProfile();
  Stream<CaptainTeam?> watchMyTeam();
  Stream<List<CaptainPlayer>> watchPlayers();
  Stream<List<AdminTournament>> watchTournaments();
  Stream<List<AdminTeam>> watchTeams({String? tournamentId});
  Stream<List<AdminMatch>> watchMatches({String? tournamentId});
  Stream<List<TournamentRegistration>> watchRegistrations();
  Stream<AppSettings> watchSettings();
  Future<void> ensureProfile();
  Future<void> updateProfile({required String displayName});
  Future<void> saveTeam({
    required String name,
    required String description,
    String? logoBase64,
  });
  Future<void> savePlayer({
    String? id,
    required String name,
    required PlayerPosition position,
    required int jerseyNumber,
  });
  Future<void> deletePlayer(String id);
  Future<void> registerForTournament(String tournamentId);
}
