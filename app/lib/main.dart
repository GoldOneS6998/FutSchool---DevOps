import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app/app.dart';
import 'app/firebase_web_options.dart';
import 'features/auth/data/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Web needs explicit options; Android reads its native configuration.
    await Firebase.initializeApp(options: kIsWeb ? firebaseWebOptions : null);
  } on FirebaseException {
    runApp(const FutSchoolApp());
    return;
  } on PlatformException {
    runApp(const FutSchoolApp());
    return;
  }
  runApp(FutSchoolApp(auth: FirebaseAuthService(FirebaseAuth.instance)));
}
