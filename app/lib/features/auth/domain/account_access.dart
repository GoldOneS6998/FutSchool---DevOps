/// Optional account operations; no role or password is stored in Firestore.
abstract class AccountAccess {
  Stream<bool> get verifiedChanges;
  Future<void> refreshVerification();
  Future<void> sendVerification();
  Future<void> resetPassword(String email);
}

/// A bool session alone cannot distinguish account switches in another tab.
abstract class SessionIdentityAccess {
  Stream<String?> get identityChanges;
}
