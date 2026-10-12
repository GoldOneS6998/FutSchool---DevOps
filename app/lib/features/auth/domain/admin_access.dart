/// UX gate only. Firestore rules independently enforce every operation.
abstract class AdminAccess {
  Stream<bool> get adminChanges;
  Future<void> refreshAdminAccess();
}
