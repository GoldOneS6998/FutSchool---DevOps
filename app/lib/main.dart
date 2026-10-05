import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app/app.dart';
import 'features/auth/data/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Android/iOS read native configuration after linking the Firebase project.
    await Firebase.initializeApp();
  } on FirebaseException {
    runApp(const FutSchoolApp());
    return;
  } on PlatformException {
    runApp(const FutSchoolApp());
    return;
  }
  runApp(FutSchoolApp(auth: FirebaseAuthService(FirebaseAuth.instance)));
}
