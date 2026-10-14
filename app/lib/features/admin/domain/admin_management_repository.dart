import '../../captain/domain/captain_models.dart';
export '../../captain/domain/captain_models.dart';
export 'admin_models.dart';

abstract class AdminManagementRepository {
  Stream<List<CaptainProfile>> watchCaptains();
  Stream<List<CaptainTeam>> watchCaptainTeams();
  Stream<List<CaptainPlayer>> watchPlayers(String captainUid);
  Stream<List<TournamentRegistration>> watchRegistrations();
  Stream<AppSettings> watchSettings();
  Future<void> setCaptainDisabled({
    required String uid,
    required bool disabled,
  });
  Future<void> reviewRegistration({
    required String id,
    required bool approve,
    String note = '',
  });
  Future<void> updateTournamentMetadata({
    required String id,
    required String name,
    required String description,
    required int maxTeams,
  });
  Future<void> saveSettings(AppSettings settings);
}
