// Archivo de opciones de Firebase generado para FutSchool.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'app/firebase_web_options.dart';

/// Configuración de [FirebaseOptions] para FutSchool.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no son soportadas en esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = firebaseWebOptions;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDuT7r0U-17uYFTSnL-nooD4m-0rKUeApA',
    appId: '1:72991991466:android:25765543950601921212d3',
    messagingSenderId: '72991991466',
    projectId: 'futschool-2ef84',
    storageBucket: 'futschool-2ef84.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuT7r0U-17uYFTSnL-nooD4m-0rKUeApA',
    appId: '1:72991991466:ios:25765543950601921212d3',
    messagingSenderId: '72991991466',
    projectId: 'futschool-2ef84',
    storageBucket: 'futschool-2ef84.firebasestorage.app',
    iosBundleId: 'mx.futschool.futschool',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDuT7r0U-17uYFTSnL-nooD4m-0rKUeApA',
    appId: '1:72991991466:ios:25765543950601921212d3',
    messagingSenderId: '72991991466',
    projectId: 'futschool-2ef84',
    storageBucket: 'futschool-2ef84.firebasestorage.app',
    iosBundleId: 'mx.futschool.futschool',
  );
}
