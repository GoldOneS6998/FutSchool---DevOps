// Dedicated local QA entry point. Never initializes the production project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:futschool/app/app.dart';
import 'package:futschool/features/admin/data/firestore_admin_repository.dart';
import 'package:futschool/features/admin/data/firestore_admin_management_repository.dart';
import 'package:futschool/features/auth/data/firebase_auth_service.dart';
import 'package:futschool/features/captain/data/firestore_captain_repository.dart';
import 'package:futschool/features/privacy/data/firestore_privacy_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  if (!kIsWeb || !['localhost', '127.0.0.1'].contains(Uri.base.host)) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Esta vista de QA solo funciona en el equipo local.'),
          ),
        ),
      ),
    );
    return;
  }
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'demo-local-only',
      appId: '1:123:web:demo',
      messagingSenderId: '123',
      projectId: 'demo-futschool-admin',
      authDomain: 'localhost',
    ),
  );
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  await auth.useAuthEmulator('127.0.0.1', 9099);
  firestore.useFirestoreEmulator('127.0.0.1', 8080);
  firestore.settings = const Settings(persistenceEnabled: false);
  runApp(
    Banner(
      message: 'QA LOCAL',
      location: BannerLocation.topEnd,
      textDirection: TextDirection.ltr,
      layoutDirection: TextDirection.ltr,
      child: FutSchoolApp(
        auth: FirebaseAuthService(auth),
        adminRepository: FirestoreAdminRepository(
          firestore: firestore,
          auth: auth,
        ),
        managementRepository: FirestoreAdminManagementRepository(
          firestore: firestore,
          auth: auth,
        ),
        captainRepository: FirestoreCaptainRepository(
          firestore: firestore,
          auth: auth,
        ),
        privacyRepository: FirestorePrivacyRepository(firestore),
      ),
    ),
  );
}
