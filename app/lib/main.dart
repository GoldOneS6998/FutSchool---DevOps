import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'features/auth/data/firebase_auth_service.dart';
import 'features/admin/data/firestore_admin_repository.dart';
import 'features/admin/data/firestore_admin_management_repository.dart';
import 'features/captain/data/firestore_captain_repository.dart';
import 'features/privacy/data/firestore_privacy_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    runApp(const FutSchoolApp());
    return;
  }
  final auth = FirebaseAuth.instance;
  runApp(
    FutSchoolApp(
      auth: FirebaseAuthService(auth),
      privacyRepository: FirestorePrivacyRepository(FirebaseFirestore.instance),
      captainRepository: FirestoreCaptainRepository(
        firestore: FirebaseFirestore.instance,
        auth: auth,
      ),
      managementRepository: FirestoreAdminManagementRepository(
        firestore: FirebaseFirestore.instance,
        auth: auth,
      ),
      adminRepository: FirestoreAdminRepository(
        firestore: FirebaseFirestore.instance,
        auth: auth,
      ),
    ),
  );
}
