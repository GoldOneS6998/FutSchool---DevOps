import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/privacy_repository.dart';

class FirestorePrivacyRepository implements PrivacyRepository {
  FirestorePrivacyRepository(this.firestore);
  final FirebaseFirestore firestore;
  @override
  Future<PrivacyNotice> readNotice() async {
    final snapshot = await firestore
        .doc('publicPrivacy/notice')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    final data = snapshot.data();
    if (data == null) return const PrivacyNotice();
    return PrivacyNotice(
      responsible: data['privacyResponsible'] as String,
      contact: data['privacyContact'] as String,
      text: data['privacyNotice'] as String,
      version: data['privacyVersion'] as String,
    );
  }
}
